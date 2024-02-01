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

Once you have created the Service Bus namespace and queue, you will need to create a shared access policy with the **Listen** permission for the namespace.

```bash
az servicebus namespace authorization-rule create --name listener --namespace-name <namespace-name> --resource-group $RGNAME --rights Listen
```

Next, get the connection information for the Azure Service Bus queue and save the values to environment variables.

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

To run this against Azure CosmosDB, you will need to create the CosmosDB account, the database, and collection. You can do this using the Azure CLI.

> Azure CosmosDB supports multiple APIs. This app supports both the MongoDB and SQL APIs. You will need to create the database and collection based on the API you want to use.

```bash
RGNAME=<resource-group-name>
LOCNAME=<location>
COSMOSDBNAME=<cosmosdb-account-name>

az group create --name $RGNAME --location $LOCNAME

# if database requires MongoDB API
# create the database and collection
az cosmosdb create --name $COSMOSDBNAME --resource-group $RGNAME --kind MongoDB
az cosmosdb mongodb database create --account-name $COSMOSDBNAME --name orderdb --resource-group $RGNAME 
az cosmosdb mongodb collection create --account-name $COSMOSDBNAME --database-name orderdb --name orders --resource-group $RGNAME

# if database requires SQL API
# create the database and container
COSMOSDBPARTITIONKEY=storeId
az cosmosdb create --name $COSMOSDBNAME --resource-group $RGNAME --kind GlobalDocumentDB
az cosmosdb sql database create --account-name $COSMOSDBNAME --name orderdb --resource-group $RGNAME
az cosmosdb sql container create --account-name $COSMOSDBNAME --database-name orderdb --name orders --resource-group $RGNAME --partition-key-path /$COSMOSDBPARTITIONKEY
```

Next, get the connection information for the Azure Service Bus queue and save the values to environment variables.

```bash
COSMOSDBUSERNAME=$COSMOSDBNAME
COSMOSDBPASSWORD=$(az cosmosdb keys list --name $COSMOSDBNAME --resource-group $RGNAME --query primaryMasterKey -o tsv)
```

Finally, set the environment variables.

```bash
# if database requires MongoDB API
# set the following environment variables
export ORDER_DB_API=mongodb
export ORDER_DB_URI=mongodb://$COSMOSDBNAME.mongo.cosmos.azure.com:10255/?retryWrites=false
export ORDER_DB_NAME=orderdb
export ORDER_DB_COLLECTION_NAME=orders
export ORDER_DB_USERNAME=$COSMOSDBUSERNAME
export ORDER_DB_PASSWORD=$COSMOSDBPASSWORD

# if database requires SQL API
# set the following environment variables
export ORDER_DB_API=cosmosdbsql
export ORDER_DB_URI=https://$COSMOSDBNAME.documents.azure.com:443/
export ORDER_DB_NAME=orderdb
export ORDER_DB_CONTAINER_NAME=orders
export ORDER_DB_PASSWORD=$COSMOSDBPASSWORD
export ORDER_DB_PARTITION_KEY=$COSMOSDBPARTITIONKEY
export ORDER_DB_PARTITION_VALUE="pets"
```

> NOTE: With Azure CosmosDB, you must ensure the orderdb database and an unsharded orders collection exist before running the app. Otherwise you will get a "server selection error".

## Running the app locally

The app relies on RabbitMQ and MongoDB. Additionally, to simulate orders, you will need to run the [order-service](../order-service) with the [virtual-customer](../virtual-customer) app. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `makeline-service` directory. Then run the following command:

```bash
docker compose up
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
