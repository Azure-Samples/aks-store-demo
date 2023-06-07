# makeline-service

To run this service locally, you will need to ensure you have the following tools running:

- RabbitMQ
- Redis
- MongoDB

Set environment variables

```bash
export RABBITMQ_CONNECTION_STRING=amqp://username:password@localhost:5672/
export RABBITMQ_QUEUE_NAME=orders
export REDIS_CONNECTION_STRING=redis://localhost:6379/0
export MONGO_CONNECTION_STRING=mongodb://localhost:27017
export MONGO_DATABASE_NAME=orderdb
export MONGO_COLLECTION_NAME=orders
```

> If you have a username and password set for Redis use this format: `redis://<user>:<pass>@localhost:6379/<db>`

To run the service locally, run the following commands

```bash
go get .
go run .
```

Run the following command to pull orders from the RabbitMQ and dump into Redis

```bash
curl http://localhost:3001/fetch
```

Run the following command to get an order for processing

```bash
curl http://localhost:3001/order/:id # where :id is the order id
```

Run the following command to put the order back for later processing

```bash
curl -X PUT http://localhost:3001/order/:id/incomplete # where :id is the order id
```

> If you put an order back for processing, you will need to get the order again to process it

Run the following command to complete the processing of an order

```bash
curl -X PUT http://localhost:3001/order/:id/complete # where :id is the order id
```

Now you can run the following command to get the order from MongoDB

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
```
