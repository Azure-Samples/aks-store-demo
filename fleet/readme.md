# Deploy AKS Store Demo to multiple clusters using GitOps

1. Enable Flux extension on the Azure Kubernetes Fleet Manager - requires a hub cluster.

```bash
az k8s-extension create \
  --resource-group {rg-fleet-test-group} \
  --cluster-name {fleet-name} \
  --cluster-type fleets \
  --name flux \
  --extension-type microsoft.flux
```

1. Create a namespace on your Fleet Manager hub cluster named `aks-store-demo`.

1. Distribute the new namespace all member clusters, excluding any existing or future child resources by specifying `selectionScope: NamespaceOnly`. You can create the on the Fleet Manager hub cluster manually via `kubectl` or via the Azure portal. If you use the Azure portal you need to manually add the `selectionScope` before applying.

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

1. Authorize the `flux-applier` user on the hub cluster to manage resources in the newly created namespace. Modify `rules` to meet your requirements. In this configuration Flux can manage any resoure type in the `aks-store-demo` namespace. You can apply via `kubectl` on the hub cluster, or via the Azure portal by using the _Apply YAML_ option, pasting in the below and then applying.

> NOTE: you can use a `ResourcePlacement` to distribute this mapping across member clusters as required.

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

1. Bootstrap your configuration by applying these resources to the `aks-store-demo` namespace on the Fleet Manager hub cluster. You can create the on the Fleet Manager hub cluster manually via `kubectl` or via the Azure portal by using the _Apply YAML_ option, pasting in the below and then applying.
   1. Try the OCI deployment by setting `spec.path` in the `Kustomization` to point at [./aks-store-demo-oci](./aks-store-demo-oci).
   1. Try the Helm deployment by setting `spec.path` in the `Kustomization` to point at [./aks-store-demo-helm](./aks-store-demo-helm).

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: git-repo-fleet-config
  namespace: aks-store-demo
spec:
  interval: 1m
  url: https://github.com/sjwaight/fleet-gitops-01
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
  sourceRef:
    kind: GitRepository
    name: git-repo-fleet-config
  path: ./aks-store-demo-helm
  prune: true
```

The resources contained in the aks-store-demo folder will be syncronized by Flux to the Fleet Manager hub cluster, then distributed to member clusters using Fleet Manager resource placement.

### What happens on the hub cluster?

When Flux synchronizes the GitRepo source, the manifests in the selected folder are applied and the Kustomization runs.

The file contents in the folder perform the following function:

- [app-kustomization.yaml](./aks-store-demo/app-kustomization.yaml) - Kustomization that runs on each member cluster, deploying the contents of the OCIRepository.
- [app-source.yaml](./aks-store-demo/app-source.yaml) - OCIRepository source that points to the artifact to deploy.
- [fleet-resource-override.yaml](./aks-store-demo/fleet-resource-override.yaml) - A Fleet Manager resource placement override that removes the `suspend` from the app components when they are distributed to member clusters.
- [fleet-resource-placement.yaml](./aks-store-demo/fleet-resource-placement.yaml) - A Fleet Manager resource placement that selects the OCIRepository and Kustomization resources and distributes them to all clusters.
- [hub-kustomization.yaml](./aks-store-demo/hub-kustomization.yaml) - Kustomization that runs on the Fleet Manager hub cluster and is responsible for processing the manifests in the folder.

> Note: both app components are bundled with `suspend` set to `true` so that the resources aren't reconciled on the Fleet Manager hub cluster. The hub cluster can't schedule workloads, so there's no impact other than an unecessary use of scheduler time on the hub.

## Enable Flux on member clusters

The OCIRepository and Kustomization resources are distributed to member clusters, leaving local reconciliation to Flux on the cluster.

1. Enable the Flux extension on member clusters (AKS or Arc-enabled Kubernetes)

```bash
az k8s-extension create \
  --resource-group {rg-test-group} \
  --cluster-name {cluster-name} \
  --cluster-type managedClusters \
  --name flux \
      --extension-type microsoft.flux
```

1. As we don't use the FluxConfig ARM resource to configure this cluster, we must manually authorize the `flux-applier` so that the Kustomize controller works as expected. Patch using the same YAML as shown above.

> NOTE: assumption is that if a cluster has the ARM extension already installed it likely also has a FluxConfig ARM resource in place that has already authorized `flux-applier`.

## View the running application

You can view the workloads and services configured by the sample application on the member clusters.

### Workloads

![Application workloads](./img/petstore-workloads.png)

### Services

![Application services](./img/petstore-services.png)

View the admin and store front web applications by selecting the `External IP` which will open them in the web browser.

![Application services](./img/petstore-storefront.png)
