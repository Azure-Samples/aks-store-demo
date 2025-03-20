# makeline-service

This is a Golang app that provides an API for processing orders. It is meant to be used in conjunction with the [store-admin](../store-admin) app.

It is a simple REST API written with the Gin framework that allows you to process orders from a RabbitMQ queue and send them to a MongoDB database.

## Prerequisites

- [Go](https://golang.org/doc/install)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [MongoSH](https://docs.mongodb.com/mongodb-shell/install/)

## Message queue options

This app can connect to either RabbitMQ or Azure Service Bus using AMQP 1.0. To connect to either of these services, you will need to provide appropriate environment variables for connecting to the message queue.

### Option 1: RabbitMQ

To run this against RabbitMQ. A docker-compose file is provided to make this easy. This will run RabbitMQ, the RabbitMQ Management UI, and enable the `rabbitmq_amqp1_0` plugin. The plugin is necessary to connect to RabbitMQ using AMQP 1.0.

With the services running, open a new terminal and navigate to the `makeline-service` directory.

Set the connection information for the RabbitMQ queue by running the following commands to set the environment variables:

```bash
export ORDER_QUEUE_URI=amqp://localhost
export ORDER_QUEUE_USERNAME=username
export ORDER_QUEUE_PASSWORD=password
export ORDER_QUEUE_NAME=orders
```

### Option 2: Azure Service Bus

To run this against Azure Service Bus, you will need to create a Service Bus namespace and a queue. You can do this using the Azure CLI.

```bash
RGNAME=<resource-group-name>
LOCNAME=<location>

az group create --name $RGNAME --location $LOCNAME
az servicebus namespace create --name <namespace-name> --resource-group $RGNAME
az servicebus queue create --name orders --namespace-name <namespace-name> --resource-group $RGNAME
```

Once you have created the Service Bus namespace and queue, you will need to decide on the authentication method. You can create a shared access policy with the **Send** permission for the queue or use Microsoft Entra Workload Identity for a passwordless experience (this is the recommended approach).

If you choose to use Workload Identity, you will need to assign the `Azure Service Bus Data Receiver` role to the identity that is running the app, which in this case will be your account. You can do this using the Azure CLI.

```bash
PRINCIPALID=$(az ad signed-in-user show --query objectId -o tsv)
SERVICEBUSBID=$(az servicebus namespace show --name <namespace-name> --resource-group <resource-group-name> --query id -o tsv)

az role assignment create --role "Azure Service Bus Data Receiver" --assignee $PRINCIPALID --scope $SERVICEBUSBID
```

Next, get the hostname for the Azure Service Bus.

```bash
HOSTNAME=$(az servicebus namespace show --name <namespace-name> --resource-group <resource-group-name> --query serviceBusEndpoint -o tsv | sed 's/https:\/\///;s/:443\///')
```

Finally, set the environment variables.

```bash
export ORDER_QUEUE_HOSTNAME=$HOSTNAME
export ORDER_QUEUE_NAME=orders
export USE_WORKLOAD_IDENTITY_AUTH=true
```

If you choose to use a shared access policy, you can create one using the Azure CLI. Otherwise, you can skip this step and proceed to [provision a database](#database-options).

```bash
az servicebus namespace authorization-rule create --name listener --namespace-name <namespace-name> --resource-group $RGNAME --rights Listen
```

Next, get the connection information for the Azure Service Bus.

```bash
HOSTNAME=$(az servicebus namespace show --name <namespace-name> --resource-group $RGNAME --query serviceBusEndpoint -o tsv | sed 's/https:\/\///;s/:443\///')
PASSWORD=$(az servicebus namespace authorization-rule keys list --namespace-name <namespace-name> --resource-group $RGNAME --name listener --query primaryKey -o tsv)
```

Finally, set the environment variables.

```bash
export ORDER_QUEUE_URI=amqps://$HOSTNAME
export ORDER_QUEUE_USERNAME=listener
export ORDER_QUEUE_PASSWORD=$PASSWORD
export ORDER_QUEUE_NAME=orders
```

> NOTE: If you are using Azure Service Bus, you will want your `order-service` to write orders to it instead of RabbitMQ. If that is the case, then you'll need to update the [`docker-compose.yml`](./docker-compose.yml) and modify the environment variables for the `order-service` to include the proper connection info to connect to Azure Service Bus. Also you will need to add the `ORDER_QUEUE_TRANSPORT=tls` configuration to connect over TLS.

## Database options

You also have the option to write orders to either MongoDB or Azure CosmosDB.

### Option 1: MongoDB

If you are using a local MongoDB container, run the following commands:

```bash
export ORDER_DB_URI=mongodb://localhost:27017
export ORDER_DB_NAME=orderdb
export ORDER_DB_COLLECTION_NAME=orders
```

### Option 2: Azure CosmosDB

To run this against Azure CosmosDB, you will need to create the CosmosDB account, the database, and collection/container. You can do this using the Azure CLI.

Run the following command to create the resource group for the Azure CosmosDB Account.

```bash
RGNAME=<resource-group-name>
LOCNAME=<location>
az group create --name $RGNAME --location $LOCNAME
```

Also note that Azure CosmosDB supports multiple APIs. This app supports both the MongoDB and SQL APIs. Choosing one model over the other has significant implications on the authentication method your app can use.

If you choose to use the MongoDB API, then you are limited to using account keys to authenticate. If you choose to use the SQL API, then you can use Microsoft Entra Workload Identity for a passwordless experience (this is the recommended approach).

If you choose to use Workload Identity, you will need to do the following tasks:

1. Assign the built-in `DocumentDB Account Contributor` role to the identity that is running the app, which in this case will be your account.
1. Create a custom role for reading and writing data using Azure RBAC and assign it to the identity that is running the app, which in this case will be your account.
1. Disable the account key authentication method for the CosmosDB account (this is highly recommended).

You can do this using the Azure CLI.

```bash
# create the cosmosdb account
COSMOSDBNAME=<cosmosdb-account-name>
az cosmosdb create --name $COSMOSDBNAME --resource-group $RGNAME --kind GlobalDocumentDB --minimal-tls-version Tls12

PRINCIPALID=$(az ad signed-in-user show --query id -o tsv)
COSMOSDBID=$(az cosmosdb show --name $COSMOSDBNAME --resource-group $RGNAME --query id -o tsv)
ROLEID=$(az role definition list -n "DocumentDB Account Contributor" --query "[].id" -o tsv)

# grant yourself the DocumentDB Account Contributor role
az role assignment create --role $ROLEID --assignee $PRINCIPALID --scope $COSMOSDBID

# create a custom role for reading and writing data
cat <<EOF > customRole.json
{
    "RoleName": "MyCosmosDBDataContributor",
    "Type": "CustomRole",
    "AssignableScopes": ["${COSMOSDBID}"],
    "Permissions": [{
        "DataActions": [
            "Microsoft.DocumentDB/databaseAccounts/readMetadata",
            "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
            "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*",
        ]
    }]
}
EOF

ROLEDEFINITIONID=$(az cosmosdb sql role definition create --account-name $COSMOSDBNAME --resource-group $RGNAME --body @customRole.json --query id -o tsv)

# assign the custom role to yourself
az cosmosdb sql role assignment create --account-name $COSMOSDBNAME --resource-group $RGNAME --scope $COSMOSDBID --principal-id $PRINCIPALID --role-definition-id $ROLEDEFINITIONID

# disable account key authentication
az cosmosdb update --name $COSMOSDBNAME --resource-group $RGNAME --disable-key-based-metadata-write-access
```

If you are using the SQL API, you will need to create the database and container. Run the following commands to create the database and container.

```bash
COSMOSDBPARTITIONKEY=storeId
az cosmosdb sql database create --account-name $COSMOSDBNAME --name orderdb --resource-group $RGNAME
az cosmosdb sql container create --account-name $COSMOSDBNAME --database-name orderdb --name orders --resource-group $RGNAME --partition-key-path /$COSMOSDBPARTITIONKEY
```

If you are using the MongoDB API, you will need to create the database and collection. Run the following commands to create the database and collection.

```bash
az cosmosdb create --name $COSMOSDBNAME --resource-group $RGNAME --kind MongoDB --minimal-tls-version Tls12
az cosmosdb mongodb database create --account-name $COSMOSDBNAME --name orderdb --resource-group $RGNAME
az cosmosdb mongodb collection create --account-name $COSMOSDBNAME --database-name orderdb --name orders --resource-group $RGNAME
```

If you are not using Workload Identity authentication, get the password for the Azure CosmosDB account and save the values to environment variables. Otherwise, skip this step.

```bash
COSMOSDBUSERNAME=$COSMOSDBNAME
COSMOSDBPASSWORD=$(az cosmosdb keys list --name $COSMOSDBNAME --resource-group $RGNAME --query primaryMasterKey -o tsv)
```

Finally, set the environment variables.

```bash
# if database requires SQL API with Workload Identity
# set the following environment variables
export USE_WORKLOAD_IDENTITY_AUTH="true"
export ORDER_DB_API=cosmosdbsql
export ORDER_DB_URI=https://$COSMOSDBNAME.documents.azure.com:443/
export ORDER_DB_NAME=orderdb
export ORDER_DB_CONTAINER_NAME=orders
export ORDER_DB_PARTITION_KEY=$COSMOSDBPARTITIONKEY
export ORDER_DB_PARTITION_VALUE="pets"

# if database requires SQL API with account key
# set the following environment variables
export ORDER_DB_API=cosmosdbsql
export ORDER_DB_URI=https://$COSMOSDBNAME.documents.azure.com:443/
export ORDER_DB_NAME=orderdb
export ORDER_DB_CONTAINER_NAME=orders
export ORDER_DB_PASSWORD=$COSMOSDBPASSWORD
export ORDER_DB_PARTITION_KEY=$COSMOSDBPARTITIONKEY
export ORDER_DB_PARTITION_VALUE="pets"

# if database requires MongoDB API with Workload Identity
# set the following environment variables
export USE_WORKLOAD_IDENTITY_AUTH=true
export ORDER_DB_API=mongodb
export ORDER_DB_LIST_CONNECTION_STRING_URL=https://management.azure.com$(az cosmosdb show -g $RGNAME -n $COSMOSDBNAME --query id -otsv)/listConnectionStrings?api-version=2021-04-15
export ORDER_DB_NAME=orderdb
export ORDER_DB_COLLECTION_NAME=orders

# if database requires MongoDB API with account key
# set the following environment variables
export ORDER_DB_API=mongodb
export ORDER_DB_URI=mongodb://$COSMOSDBNAME.mongo.cosmos.azure.com:10255/?retryWrites=false
export ORDER_DB_NAME=orderdb
export ORDER_DB_COLLECTION_NAME=orders
export ORDER_DB_USERNAME=$COSMOSDBUSERNAME
export ORDER_DB_PASSWORD=$COSMOSDBPASSWORD
```

> NOTE: With Azure CosmosDB, you must ensure the orderdb database and an unsharded orders collection exist before running the app. Otherwise you will get a "server selection error".

## Running the app locally

The app relies on RabbitMQ and MongoDB. Additionally, to simulate orders, you will need to run the [order-service](../order-service) with the [virtual-customer](../virtual-customer) app. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `makeline-service` directory. Then run the following command:

```bash
docker compose up -d
```

Now you can run the following commands to start the application:

```bash
go get .
go run .
```

When the app is running, you should see output similar to the following:

```text
[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:   export GIN_MODE=release
 - using code:  gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /order/fetch              --> main.fetchOrders (4 handlers)
[GIN-debug] GET    /order/:id                --> main.getOrder (4 handlers)
[GIN-debug] PUT    /order                    --> main.updateOrder (4 handlers)
[GIN-debug] GET    /health                   --> main.main.func1 (4 handlers)
[GIN-debug] [WARNING] You trusted all proxies, this is NOT safe. We recommend you to set a value.
Please check https://pkg.go.dev/github.com/gin-gonic/gin#readme-don-t-trust-all-proxies for details.
[GIN-debug] Listening and serving HTTP on :3001
```

Using the [`test-makeline-service.http`](./test-makeline-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.

To view the orders in MongoDB, open a terminal and run the following command:

```bash
# connect to mongodb
mongosh

# show databases and confirm orderdb exists
show dbs

# use orderdb
use orderdb

# show collections and confirm orders exists
show collections

# get the orders
db.orders.find()

# get completed orders
db.orders.findOne({status: 1})
```

To view the orders in Azure CosmosDB using `mongosh`, open a terminal an run the following command:

```bash
# connect to cosmosdb
mongosh -u $USERNAME -p $PASSWORD --tls --retryWrites=false mongodb://$COSMOSDBNAME.mongo.cosmos.azure.com:10255/orderdb

# show collections and confirm orders exists
show collections

# get the orders
db.orders.find()

# get completed orders
db.orders.findOne({status: 1})
```
