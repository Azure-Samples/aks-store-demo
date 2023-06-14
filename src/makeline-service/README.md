# makeline-service

To run this service locally, you will need to ensure you have the following tools running:

- RabbitMQ
- MongoDB

Set environment variables

```bash
export RABBITMQ_CONNECTION_STRING=amqp://username:password@localhost:5672/
export RABBITMQ_QUEUE_NAME=orders
export MONGO_CONNECTION_STRING=mongodb://localhost:27017
export MONGO_DATABASE_NAME=orderdb
export MONGO_COLLECTION_NAME=orders
```

To run the service locally, run the following commands

```bash
go get .
go run .
```

Run the following command to pull orders from the RabbitMQ and dump into MongoDB

```bash
curl http://localhost:3001/order/fetch
```

Run the following command to get an order for processing

```bash
curl http://localhost:3001/order/:id # where :id is the order id
```

Run the following command to update an order

```bash
curl -X PUT http://localhost:3001/order/:id # where :id is the order id
```

> NOTE: This only updates the status for now.

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

# get the order by id
db.orders.findOne({orderid: '45901'})
```
