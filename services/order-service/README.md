# order-service

This is a Fastify app that provides an API for submitting orders. It is meant to be used in conjunction with the [store-front](../store-front) app.

It is a simple REST API that allows you to add an order to a message queue that supports the AMQP 1.0 protocol.

## Prerequisites

- [Node.js](https://nodejs.org/en/download/)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)


## Message queue options

This app can connect to either RabbitMQ or Azure Service Bus using AMQP 1.0. To connect to either of these services, you will need to provide appropriate environment variables for connecting to the message queue.

### Option 1: RabbitMQ

To run this against RabbitMQ. A docker-compose file is provided to make this easy. This will run RabbitMQ, the RabbitMQ Management UI, and enable the `rabbitmq_amqp1_0` plugin. The plugin is necessary to connect to RabbitMQ using AMQP 1.0.

To run the necessary services, clone the repo, open a terminal, and navigate to the `order-service` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `order-service` directory. Then run the following commands:

```bash
cat << EOF > .env
ORDER_QUEUE_HOSTNAME=localhost
ORDER_QUEUE_PORT=5672
ORDER_QUEUE_USERNAME=username
ORDER_QUEUE_PASSWORD=password
ORDER_QUEUE_NAME=orders
EOF

# load the environment variables
source .env
```

### Option 2: Azure Service Bus

To run this against Azure Service Bus, you will need to create a Service Bus namespace and a queue. You can do this using the Azure CLI. 

```bash
az group create --name <resource-group-name> --location <location>
az servicebus namespace create --name <namespace-name> --resource-group <resource-group-name>
az servicebus queue create --name orders --namespace-name <namespace-name> --resource-group <resource-group-name>
```

Once you have created the Service Bus namespace and queue, you will need to decide on the authentication method. You can create a shared access policy with the **Send** permission for the queue or use Microsoft Entra Workload Identity for a passwordless experience (this is the recommended approach).

If you choose to use Managed Identity, you will need to assign the `Azure Service Bus Data Sender` role to the identity that is running the app, which in this case will be your account. You can do this using the Azure CLI.

```bash
PRINCIPALID=$(az ad signed-in-user show --query objectId -o tsv)
SERVICEBUSBID=$(az servicebus namespace show --name <namespace-name> --resource-group <resource-group-name> --query id -o tsv)

az role assignment create --role "Azure Service Bus Data Sender" --assignee $PRINCIPALID --scope $SERVICEBUSBID
```

Next, get the connection information for the Azure Service Bus queue and save the values to environment variables.

Next, get the hostname for the Azure Service Bus queue.

```bash
HOSTNAME=$(az servicebus namespace show --name <namespace-name> --resource-group <resource-group-name> --query serviceBusEndpoint -o tsv | sed 's/https:\/\///;s/:443\///')
```

Finally, save the environment variables to a `.env` file.

```bash
cat << EOF > .env
USE_WORKLOAD_IDENTITY_AUTH=true
AZURE_SERVICEBUS_FULLYQUALIFIEDNAMESPACE=$HOSTNAME
ORDER_QUEUE_NAME=orders
EOF

# load the environment variables
source .env
```

If you choose to use a shared access policy, you can create one using the Azure CLI. Otherwise, you can skip this step and proceed to [running the app locally](#running-the-app-locally).

```bash
az servicebus queue authorization-rule create --name sender --namespace-name <namespace-name> --resource-group <resource-group-name> --queue-name orders --rights Send
```

Next, get the connection information for the Azure Service Bus queue.

```bash
HOSTNAME=$(az servicebus namespace show --name <namespace-name> --resource-group <resource-group-name> --query serviceBusEndpoint -o tsv | sed 's/https:\/\///;s/:443\///')

PASSWORD=$(az servicebus queue authorization-rule keys list --namespace-name <namespace-name> --resource-group <resource-group-name> --queue-name orders --name sender --query primaryKey -o tsv)
```

Finally, save the environment variables to a `.env` file.

```bash
cat << EOF > .env
ORDER_QUEUE_HOSTNAME=$HOSTNAME
ORDER_QUEUE_PORT=5671
ORDER_QUEUE_USERNAME=sender
ORDER_QUEUE_PASSWORD="$PASSWORD"
ORDER_QUEUE_TRANSPORT=tls
ORDER_QUEUE_RECONNECT_LIMIT=10
ORDER_QUEUE_NAME=orders
EOF

# load the environment variables
source .env
```

## Running the app locally

To run the app, run the following command:

```bash
npm install
npm run dev
```

When the app is running, you should see output similar to the following:

```text
> order-service@1.0.0 dev
> fastify start -w -l info -P app.js

[1687920999327] INFO (108877 on yubuntu): Server listening at http://[::1]:3000
[1687920999327] INFO (108877 on yubuntu): Server listening at http://127.0.0.1:3000
```

## Testing the API

Using the [`test-order-service.http`](./test-order-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.

To view the order messages in RabbitMQ, open a browser and navigate to [http://localhost:15672](http://localhost:15672). Log in with the username and password you provided in the environment variables above. Then click on the **Queues** tab and click on your **orders** queue. After you've submitted a few orders, you should see the messages in the queue.