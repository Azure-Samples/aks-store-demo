# makeline-service

This is a Golang app that provides an API for processing orders. It is meant to be used in conjunction with the [store-admin](../store-admin) app.

It is a simple REST API written with the Gin framework that allows you to process orders from a RabbitMQ queue and send them to a MongoDB database.

## Running the app locally

### Prerequisites

- [Go](https://golang.org/doc/install)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [MongoSH](https://docs.mongodb.com/mongodb-shell/install/)

### Running the app

The app relies on RabbitMQ and MongoDB. Additionally, to simulate orders, you will need to run the [order-service](../order-service) with the [virtual-customer](../virtual-customer) app. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `makeline-service` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `makeline-service` directory. Then run the following commands:

```bash
export ORDER_QUEUE_CONNECTION_STRING=amqp://username:password@localhost:5672/
export ORDER_QUEUE_NAME=orders
export ORDER_DB_CONNECTION_STRING=mongodb://localhost:27017
export ORDER_DB_NAME=orderdb
export ORDER_DB_COLLECTION_NAME=orders

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

Using the [`test.http`](../../test.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.

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
