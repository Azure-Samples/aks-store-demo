# AKS Store Demo

This sample demo app consists of a group of containerized microservices that can be easily deployed into an Azure Kubernetes Service (AKS) cluster. This is meant to show a realistic scenario using a polyglot architecture, event-driven design, and common open source back-end services (eg - RabbitMQ, MongoDB). The application also leverages OpenAI's GPT-3 models to generate product descriptions. This can be done using either [Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/overview) or [OpenAI](https://openai.com/).

This application is inspired by another demo app called [Red Dog](https://github.com/Azure/reddog-code).

> [!NOTE]
> This is not meant to be an example of perfect code to be used in production, but more about showing a realistic application running in AKS. 

<!-- 
To walk through a quick deployment of this application, see the [AKS Quickstart](https://learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli).

To walk through a complete experience where this code is packaged into container images, uploaded to Azure Container Registry, and then run in and AKS cluster, see the [AKS Tutorials](https://learn.microsoft.com/azure/aks/tutorial-kubernetes-prepare-app).

 -->

## Architecture

The application has the following services: 

| Service | Description |
| --- | --- |
| `makeline-service` | This service handles processing orders from the queue and completing them (Golang) |
| `order-service` | This service is used for placing orders (Javascript) |
| `product-service` | This service is used to perform CRUD operations on products (Rust) |
| `store-front` | Web app for customers to place orders (Vue.js) |
| `store-admin` | Web app used by store employees to view orders in queue and manage products (Vue.js) | 
| `virtual-customer` | Simulates order creation on a scheduled basis (Rust) |
| `virtual-worker` | Simulates order completion on a scheduled basis (Rust) |
| `ai-service` | Optional service for adding generative text and graphics creation (Python) |
| `mongodb` | MongoDB instance for persisted data |
| `rabbitmq` | RabbitMQ for an order queue |

![Logical Application Architecture Diagram](assets/demo-arch-with-openai.png)

## Run the app on Azure Kubernetes Service (AKS)

To learn how to deploy this app on AKS, see [Quickstart: Deploy an Azure Kubernetes Service (AKS) cluster using Azure CLI](https://learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli).

> [!NOTE]
> The above article shows a simplified version of the store app with some services removed. For the full application, you can use the `aks-store-all-in-one.yaml` file in this repo.

## Run on any Kubernetes

This application uses public images stored in GitHub Container Registry and Microsoft Container Registry (MCR). Once your Kubernetes cluster of choice is setup, you can deploy the full app with the below commands.

This deployment deploys everything except the `ai-service` that integrates OpenAI. If you want to try integrating the OpenAI component, take a look at this article: [Deploy an application that uses OpenAI on Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/aks/open-ai-quickstart?tabs=aoai).

```bash
kubectl create ns pets

kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-all-in-one.yaml -n pets

```

## Run the app locally

The application is designed to be [run in an AKS cluster](#run-the-app-on-aks), but can also be run locally using Docker Compose.

> [!TIP]
> You must have [Docker Desktop](https://www.docker.com/products/docker-desktop) installed to run this app locally. If you do not have it installed locally, you can try opening this repo in a [GitHub Codespace instead](#run-the-app-with-github-codespaces)

To run this app locally:

Clone the repo to your development computer and navigate to the directory:

```console
git clone https://github.com/Azure-Samples/aks-store-demo.git
cd aks-store-demo
```

Configure your Azure OpenAI or OpenAI API keys in [`docker-compose.yml`](./docker-compose.yml) using the environment variables in the `ai-service` section:

```yaml
  ai-service:
    build: src/ai-service
    container_name: 'ai-service'
    ...
    environment:
      - USE_AZURE_OPENAI=True # set to False if you are not using Azure OpenAI
      - AZURE_OPENAI_DEPLOYMENT_NAME= # required if using Azure OpenAI
      - AZURE_OPENAI_ENDPOINT= # required if using Azure OpenAI
      - OPENAI_API_KEY= # always required
      - OPENAI_ORG_ID= # required if using OpenAI
    ...
```

Alternatively, if you do not have access to Azure OpenAI or OpenAI API keys, you can run the app without the `ai-service` by commenting out the `ai-service` section in [`docker-compose.yml`](./docker-compose.yml). For example:

```yaml
#  ai-service:
#    build: src/ai-service
#    container_name: 'ai-service'
...
#    networks:
#      - backend_services
```

Start the app using `docker compose`. For example:

```bash
docker compose up
```

To stop the app, you can hit the `CTRL+C` key combination in the terminal window where the app is running.

## Run the app with GitHub Codespaces

This repo also includes [DevContainer configuration](./.devcontainer/devcontainer.json), so you can open the repo using [GitHub Codespaces](https://docs.github.com/en/codespaces/overview). This will allow you to run the app in a container in the cloud, without having to install Docker on your local machine. When the Codespace is created, you can run the app using the same instructions as above.

## Run the app with Azure Service Bus and Azure Cosmos DB using Azure Developer CLI

This repo also includes an alternate deployment type that uses Azure Service Bus and Azure Cosmos DB instead of RabbitMQ and MongoDB. To deploy this version of the app, you can use the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview) with a GitHub Codespace or DevContainer which has all the tools (e.g., `azure-cli`, `azd`, `terraform`, `kubectl`, and `helm`) pre-installed. This deployment will use Terraform to provision the Azure resources then retrieve output variables and pass them to Helm to deploy the app.

To get started, authenticate to Azure using the Azure Developer CLI and Azure CLI.

```bash
# authenticate to Azure Developer CLI
azd auth login

# authenticate to Azure CLI
az login
```

> Note: This project is configured to be deployed with Terraform by default. If you want to deploy using the bicep template, please rename the `azure-bicep.yaml` file to `azure.yaml`.

Deploy the app with a single command.
> [!WARNING]
> Before you run the `azd up` command, make sure that you have the "Owner" role on the subscription you are deploying to. This is because the Terraform templates will create Azure role based access control (RBAC) assignments. Otherwise, the deployment will fail.

The `makeline-service` supports both MongoDB and SQL API for accessing data in Azure CosmosDB. The default API is `MongoDB`, but you can use SQL API. To use the SQL API for Azure CosmosDB, you must provision the service using the `GlobalDocumentDB` account kind. You can set the Azure CosmosDB account kind by running the following command prior to running `azd up`:

```bash
azd env set AZURE_COSMOSDB_ACCOUNT_KIND GlobalDocumentDB
```

By default, all application containers will be sourced from the [GitHub Container Registry](https://github.com/orgs/Azure-Samples/packages?repo_name=aks-store-demo). If you want to deploy apps from an Azure Container registry instead, you can do so by setting the following environment variable.

```bash
azd env set DEPLOY_AZURE_CONTAINER_REGISTRY true
```

This will instruct the Terraform templates to provision an Azure Container Registry and enable authentication from the AKS cluster.

When you choose to deploy containers from Azure Container Registry, you will have the option to import containers from GitHub Container Registry using the `az acr import` command or build containers from source using the `az acr build` command. 

To build containers from source, run the following command. 

```bash
azd env set BUILD_CONTAINERS true
```

Provision and deploy the app with a single command.

```bash
azd up
```
> [!WARNING]
> When selecting an Azure region, make sure to choose one that supports all the services used in this app including Azure OpenAI, Azure Kubernetes Service, Azure Service Bus, Azure Cosmos DB, Azure Log Analytics Workspace, Azure Monitor workspace, and Azure Managed Grafana.

Once the deployment is complete, you can verify all the services are running and the app is working by following these steps:

- In the Azure portal, navigate to your Azure Service Bus resource and use Azure Service Bus explorer to check for order messages
- In the Azure portal, navigate to your Azure Cosmos DB resource and use the database explorer to check for order records

## Additional Resources

- AKS Documentation. https://learn.microsoft.com/azure/aks
- Kubernetes Learning Path. https://azure.microsoft.com/resources/kubernetes-learning-path 
