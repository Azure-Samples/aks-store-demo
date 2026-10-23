# Use Azure Kubernetes Fleet Manager and GitOps to deploy to multiple clusters using GitOps

You can use the Flux extension on [Azure Kubernetes Fleet Manager](https://aka.ms/kubernetes-fleet/) to control the rollout of the AKS store demo application across multiple clusters.

This guide assumes you have created a Fleet Manager with a hub cluster and have added one or more Kubernetes clusters that are already configured with Flux.

1. For the subscription where Fleet Manager is deployed, register the following Azure resource providers.

   ```bash
   az provider register --namespace Microsoft.Kubernetes
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.KubernetesConfiguration
   ```

1. You need the `k8s-extension` and `fleet` Azure CLI extensions. You can install them by running the following commands.

   ```bash
   az extension add --name k8s-extension
   az extension add --name fleet
   ```

   Run the `az extension update` command to update to the latest version of the extensions.

   ```bash
   az extension update --name k8s-extension
   az extension update --name fleet
   ```

1. Enable the Flux extension on the Fleet Manager hub cluster.

   ```bash
   az k8s-extension create \
       --name flux \
       --extension-type microsoft.flux \
       --cluster-name ${FLEET} \
       --resource-group ${GROUP} \
       --cluster-type fleets \
       --scope cluster
   ```

   If you want to limit Flux to managing resources in a specific namespace, provide the namespace by using the `--release-namespace` parameter and update the `--scope` argument to `namespace`.

1. Get the kubeconfig file of the Fleet Manager hub cluster by using the [`az fleet get-credentials`][az-fleet-get-credentials] command:

   ```azurecli-interactive
   az fleet get-credentials \
       --resource-group ${GROUP} \
       --name ${FLEET}
   ```

1. Create a namespace on your Fleet Manager hub cluster named `aks-store-demo`.

   ```bash
   kubectl create namespace aks-store-demo
   ```

1. Authorize the `flux-applier` user on the hub cluster to manage resources in the newly created namespace. Modify `rules` to meet your requirements. In this configuration Flux can manage any resource type in the `aks-store-demo` namespace. You can apply via `kubectl` on the hub cluster, or via the Azure portal by using the _Apply YAML_ option, pasting in the below and then applying.

   > NOTE: you could also use a `ResourcePlacement` to distribute this authorization across member clusters so that Flux is authorized to reconcile resources there also.

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: flux-applier
     namespace: aks-store-demo
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: flux-applier
     namespace: aks-store-demo
   rules:
     - apiGroups: ["*"]
       resources: ["*"]
       verbs: ["*"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: flux-applier
     namespace: aks-store-demo
   subjects:
     - kind: ServiceAccount
       name: flux-applier
       namespace: aks-store-demo
   roleRef:
     kind: Role
     name: flux-applier
     apiGroup: rbac.authorization.k8s.io
   ```

1. Distribute the new namespace all member clusters using [Azure Kubernetes Fleet Manager resource placement](https://aka.ms/kubernetes-fleet/placement). We exclude any existing or future child resources by specifying `selectionScope: NamespaceOnly`.

   ```yaml
   apiVersion: placement.kubernetes-fleet.io/v1
   kind: ClusterResourcePlacement
   metadata:
     name: distribute-test-app
   spec:
     resourceSelectors:
       - group: ""
         kind: Namespace
         version: v1
         name: aks-store-demo
         selectionScope: NamespaceOnly
     policy:
       placementType: PickAll
   ```

1. Connect the source repository with the Fleet Manager hub cluster, selecting which artifact type to deploy. You can create these on the Fleet Manager hub cluster manually via `kubectl`.
   1. Try the OCI deployment by setting `spec.path` in the `Kustomization` to point at [./fleet/aks-store-fleet-oci](./aks-store-fleet-oci).
   1. Try the Helm deployment by setting `spec.path` in the `Kustomization` to point at [./fleet/aks-store-fleet-helm](./aks-store-fleet-helm).

   ```yaml
   apiVersion: source.toolkit.fluxcd.io/v1
   kind: GitRepository
   metadata:
     name: git-repo-fleet-config
     namespace: aks-store-demo
   spec:
     interval: 1m
     url: https://github.com/azure-samples/aks-store-demo
     ref:
       branch: main
   ---
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
     name: kustomize-fleet-config
     namespace: aks-store-demo
   spec:
     interval: 1m
     prune: true
     path: ./fleet/aks-store-fleet-helm
     sourceRef:
       kind: GitRepository
       name: git-repo-fleet-config
   ```

   > NOTE: You can use other supported Flux source and release types as required.

   The resources contained in the aks-store-demo folder will be synchronized by Flux to the Fleet Manager hub cluster, then distributed to member clusters using Fleet Manager resource placement.

## What happens on the hub cluster?

When Flux synchronizes the GitRepo source, the manifests in the selected folder are applied and the Kustomization runs.

The Fleet Manager hub cluster doesn't run the staged workloads. If you review the pods on the hub cluster you will see that they remain unscheduled. This is intended.

The file contents in the folder perform the following functions.

### OCI Artifact

- [app-kustomization.yaml](./aks-store-fleet-oci/app-kustomization.yaml) - Kustomization that runs on each member cluster, deploying the contents of the OCIRepository.
- [app-source.yaml](./aks-store-fleet-oci/app-source.yaml) - OCIRepository source that points to the artifact to deploy.
- [fleet-resource-override.yaml](./aks-store-fleet-oci/fleet-resource-override.yaml) - A Fleet Manager resource placement override that removes the `suspend` from the app components when they are distributed to member clusters.
- [fleet-resource-placement.yaml](./aks-store-fleet-oci/fleet-resource-placement.yaml) - A Fleet Manager resource placement that selects the OCIRepository and Kustomization resources and distributes them to all clusters.

### Helm Chart

- [app-release.yaml](./aks-store-fleet-helm/app-release.yaml) - HelmRelease that runs on each member cluster, deploying the contents of the HelmRepository.
- [app-source.yaml](./aks-store-fleet-helm/app-source.yaml) - HelmRepository source that points to the repository containing the Helm chart to deploy.
- [fleet-resource-override.yaml](./aks-store-fleet-helm/fleet-resource-override.yaml) - A Fleet Manager resource placement override that removes the `suspend` from the app components when they are distributed to member clusters.
- [fleet-resource-placement.yaml](./aks-store-fleet-helm/fleet-resource-placement.yaml) - A Fleet Manager resource placement that selects the HelmRepository and HelmRelease resources and distributes them to all clusters.

> Note: both app components are bundled with `suspend` set to `true` so that the resources aren't reconciled on the Fleet Manager hub cluster. The hub cluster can't schedule workloads, so there's no impact other than an unnecessary use of scheduler time on the hub.

## View the running application

You can view the workloads and services configured by the sample application on the member clusters.

1. Get the kubeconfig file of the Fleet Manager hub cluster by using the [`az fleet get-credentials`][az-fleet-get-credentials] command:

   ```azurecli-interactive
   az aks get-credentials \
       --resource-group ${GROUP} \
       --name ${AKSCLUSTER}
   ```

1. Check running services in the `aks-store-demo` namespace.

   ```bash
   kubectl get services -n aks-store-demo
   ```

   Your results should look similar to the following.

   ```output
   NAME               TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)              AGE
   documentdb         ClusterIP      10.0.160.116   <none>            10260/TCP            4h20m
   makeline-service   ClusterIP      10.0.18.157    <none>            3001/TCP             4h20m
   order-service      ClusterIP      10.0.115.69    <none>            3000/TCP             4h20m
   product-service    ClusterIP      10.0.106.112   <none>            3002/TCP             4h20m
   rabbitmq           ClusterIP      10.0.13.191    <none>            5672/TCP,15672/TCP   4h20m
   store-admin        LoadBalancer   10.0.112.214   172.131.163.xxx   80:30654/TCP         4h20m
   store-front        LoadBalancer   10.0.163.238   172.134.8.yyy     80:31027/TCP         4h20m
   ```

   Open either the `store-admin` or `store-front` external IP addresses to view the resulting web experiences for the two services.

## Other things to try out

Fleet Manager resource placement includes the concept of staged roll outs that provide additional controls beyond the default `RollingUpdate` that is used in this sample.

You can group clusters and add approvals to the rollout of your application updates without the overhead of managing branch merges. Rolling back becomes a matter of cancelling the rollout and re-applying the last good version.

Read more about staged roll outs with Fleet Manager resource placement on [Microsoft Learn](https://aka.ms/kubernetes-fleet/placement/staged-rollout).

## Uninstalling the application

The easiest way to remove the application from all clusters is to delete the `kustomize-fleet-config` Kustomization on the Fleet Manager hub cluster. This removes the resource placement on the hub cluster which in turn causes the member clusters to remove the placed resources.
