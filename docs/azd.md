# Deploying the AKS Store Demo app to Azure using Azure Developer CLI

Using the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview), you can deploy this solution to Azure in minutes. By default it ships prebuilt container images and RabbitMQ/MongoDB; you can also opt into Azure Service Bus and Azure Cosmos DB, and even build app images from source.

## Prerequisites

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=648726487)

Opening the [AKS Store Demo repo](https://github.com/Azure-Samples/aks-store-demo) in [GitHub Codespaces](https://github.com/features/codespaces) is preferred; however, if you want to run the app locally, you will need the following tools:

- [Azure CLI](https://learn.microsoft.com/cli/azure/what-is-azure-cli)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview) version 1.15.0 or later
- [Visual Studio Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kubelogin](https://azure.github.io/kubelogin/install.html)
- [Helm](https://helm.sh/docs/intro/install/)
- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [Git](https://git-scm.com/)
- [Terraform](https://www.terraform.io/)
- Bash shell

## Get started

To get started, authenticate to Azure using the Azure Developer CLI and Azure CLI.

```bash
# authenticate to Azure Developer CLI
azd auth login

# enable Helm support
azd config set alpha.aks.helm on

# enable Kustomize support (used when building from source)
azd config set alpha.aks.kustomize on

# authenticate to Azure CLI
az login
```

> [!WARNING]
> Before you run the `azd up` command, make sure that you have the "Owner" role on the subscription you are deploying to. This is because the infrastructure-as-code templates will create Azure role based access control (RBAC) assignments. Otherwise, the deployment will fail.
>
> You may also need to register the following Azure resource providers in your subscription if they are not already registered:
>
> - `Microsoft.ContainerService` (for AKS)
> - `Microsoft.KeyVault` (for Key Vault)
> - `Microsoft.CognitiveServices` (for Azure OpenAI)
> - `Microsoft.ServiceBus` (if using Service Bus)
> - `Microsoft.DocumentDB` (if using Cosmos DB)
> - `Microsoft.OperationalInsights` (if using observability tools)
> - `Microsoft.AlertsManagement` (if using observability tools)
>
> You can register these providers using the Azure CLI:
>
> ```bash
> az provider register --namespace Microsoft.ContainerService
> az provider register --namespace Microsoft.KeyVault
> az provider register --namespace Microsoft.CognitiveServices
> az provider register --namespace Microsoft.ServiceBus
> az provider register --namespace Microsoft.DocumentDB
> az provider register --namespace Microsoft.OperationalInsights
> az provider register --namespace Microsoft.AlertsManagement
> ```

When selecting an Azure region, choose one that supports all services used here: Azure OpenAI, AKS, Key Vault, Service Bus, Cosmos DB, Log Analytics, Azure Monitor (managed Prometheus), and Managed Grafana.

If you are deploying an Azure OpenAI account, you will need to ensure you have enough [tokens per minute quota](https://learn.microsoft.com/azure/ai-services/openai/how-to/quota?tabs=cli) for the `gpt-4o-mini` model. You can check your quota by running the following command:

```bash
REGION=swedencentral

az cognitiveservices usage list \
  --location $REGION \
  --query "[].{name: name.value, currentValue:currentValue, limit: limit}" \
  -o table
```

> [!TIP]
> If difference between current value and limit for `OpenAI.Standard.gpt-4o-mini` is less than 30, you can request more by following the instructions in the [Azure OpenAI documentation](https://learn.microsoft.com/azure/ai-services/openai/quotas-limits#how-to-request-increases-to-the-default-quotas-and-limits).

### Deployment settings

The infrastructure-as-code templates in this repo use variables to define the deployment settings. You can set these variables using the Azure Developer CLI and the templates will evaluate them to provision the resources.

The following environment variables control what gets deployed:

| Variable                          | Description                                                                                                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AZURE_LOCATION`                  | The Azure region for the deployment.                                                                                                                               |
| `AKS_NODE_POOL_VM_SIZE`           | AKS node VM size. Default: `Standard_D2_v4`.                                                                                                                       |
| `DEPLOY_AZURE_CONTAINER_REGISTRY` | Set `true` to provision Azure Container Registry (ACR). When enabled, images are either imported from GHCR or built to ACR and the deployment uses that registry.  |
| `BUILD_CONTAINERS`                | With ACR enabled (above), set `true` to build images from `src/*` using `az acr build`. If `false`/unset, images are imported from GHCR into ACR.                  |
| `DEPLOY_AZURE_OPENAI`             | Set `true` to deploy Azure OpenAI and enable `ai-service` with workload identity.                                                                                  |
| `AZURE_OPENAI_LOCATION`           | Region for Azure OpenAI. See [model availability](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#provisioned-deployment-model-availability). |
| `DEPLOY_IMAGE_GENERATION_MODEL`   | Set `true` to deploy DALL‑E 3 (image generation) along with Azure OpenAI.                                                                                          |
| `DEPLOY_AZURE_SERVICE_BUS`        | Set `true` to deploy Azure Service Bus (RabbitMQ disabled in app).                                                                                                 |
| `DEPLOY_AZURE_COSMOSDB`           | Set `true` to deploy Azure Cosmos DB (MongoDB disabled in app).                                                                                                    |
| `AZURE_COSMOSDB_ACCOUNT_KIND`     | Cosmos DB API kind: `MongoDB` or `GlobalDocumentDB` (SQL API). Default: `GlobalDocumentDB`.                                                                        |
| `DEPLOY_OBSERVABILITY_TOOLS`      | Set `true` to deploy Log Analytics, managed Prometheus, Managed Grafana, and enable Container Insights.                                                            |
| `SOURCE_REGISTRY`                 | Source container registry for images. Default: `ghcr.io/azure-samples`.                                                                                            |

These environment variables listed above can be set with commands like this:

```bash
# set the main deployment location
azd env set AZURE_LOCATION swedencentral

# set the SKU of the virtual machine scale set nodes in the AKS cluster
azd env set AKS_NODE_POOL_VM_SIZE Standard_D2_v4

# deploys azure container registry and imports containers from github container registry
azd env set DEPLOY_AZURE_CONTAINER_REGISTRY true

# deploys Azure OpenAI
azd env set DEPLOY_AZURE_OPENAI true

# Azure OpenAI region
azd env set AZURE_OPENAI_LOCATION swedencentral

# deploys azure service bus
azd env set DEPLOY_AZURE_SERVICE_BUS true

# deploys azure cosmos db with the sql api
azd env set DEPLOY_AZURE_COSMOSDB true

# set Cosmos DB account kind (GlobalDocumentDB for SQL API, MongoDB for MongoDB API)
azd env set AZURE_COSMOSDB_ACCOUNT_KIND GlobalDocumentDB

# deploys aks observability tools
azd env set DEPLOY_OBSERVABILITY_TOOLS true

# set custom source registry (optional)
azd env set SOURCE_REGISTRY ghcr.io/azure-samples
```

> [!NOTE]
> If none of these are set, only the AKS cluster is deployed. Workload identity is enabled by default and applied automatically to services that integrate with Azure (OpenAI, Service Bus, Cosmos DB).

## Deploy the app

Provision and deploy the app with a single command.

```bash
azd up
```

When you run the `azd up` command for the first time, you will be asked for a bit of information:

- **Environment name:** This is the name of the environment that will be created so that Azure Developer CLI can keep track of the resources that are created.
- **Azure subscription:** You will be asked to select the Azure subscription that you want to use. If you only have one subscription, it will be selected by default.
- **Azure location:** You will be asked to select the Azure location where the resources will be created. You can select the location that is closest to you but you must ensure that the location supports all the resources that will be created. If you are unsure of which region to use, select "East US 2".

After you provide the information, `azd up` registers providers/features and installs required Azure CLI extensions. It then runs Terraform to provision Azure resources and deploys the app to AKS using a Helm chart. Workload identity is configured automatically for services that talk to Azure resources.

This will take a few minutes to complete.

> [!NOTE]
> Infra defaults to [Terraform](../infra/terraform). To use [Bicep](../infra/bicep) instead, open `azure.yaml` and change:
>
> - `infra.provider: bicep`
> - `infra.path: infra/bicep`
>
> The application deployment remains Helm-based.

### Build from source (optional)

For a full source-to-ACR build and Kustomize-based deploy:

1. Swap the azd config to the build-from-source variant

```bash
mv azure.yaml azure.yaml.bak
mv azure-build-from-source.yaml azure.yaml
```

1. Ensure ACR is enabled (images will be built and pushed there)

```bash
azd env set DEPLOY_AZURE_CONTAINER_REGISTRY true
```

This flow builds Docker images for each service and deploys using Kustomize overlays.

## Validate the deployment

Once the deployment completes, `azd` prints outputs. You can get service URLs directly:

```bash
azd env get-value SERVICE_STORE_FRONT_ENDPOINT_URL
azd env get-value SERVICE_STORE_ADMIN_ENDPOINT_URL
```

You can also browse the resource group (`AZURE_RESOURCE_GROUP`) in the [Azure Portal](https://portal.azure.com). In the AKS resource, check Workloads and Services/Ingresses in the `pets` namespace. `store-front` and `store-admin` are exposed via LoadBalancers with public IPs.

If you deployed an Azure Service Bus, navigate to the resource and use Azure Service Bus explorer to check for order messages.

If you deployed an Azure CosmosDB, navigate to the resource and use the database explorer to check for order records.

## Clean up

When you are done testing the deployment, you can clean up the resources using the `azd down` command.

```bash
azd down --force --purge
```
