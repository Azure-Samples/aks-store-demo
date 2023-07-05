# order-service

This is a Fastify app that provides an API for submitting orders. It is meant to be used in conjunction with the [store-front](../store-front) app.

It is a simple REST API that allows you to add an order to a RabbitMQ queue.

## Running the app locally

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)


### Running the app

The app relies on RabbitMQ. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `order-service` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `order-service` directory. Then run the following commands:

```bash
export ORDER_QUEUE_PROTOCOL=amqp
export ORDER_QUEUE_HOSTNAME=localhost
export ORDER_QUEUE_PORT=5672
export ORDER_QUEUE_USERNAME=username
export ORDER_QUEUE_PASSWORD=password

npm install
npm run dev
```

When the app is running, you should see output similar to the following:

```text
> order-service@1.0.0 dev
> fastify start -w -l info -P app.js

[1687920999327] INFO (108877 on yubuntu): Server listening at http://127.0.0.1:3000
```

Using the [`test-order-service.http`](./test-order-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.

To view the order messages in RabbitMQ, open a browser and navigate to [http://localhost:15672](http://localhost:15672). Log in with the username and password you provided in the environment variables above. Then click on the **Queues** tab and click on your **orders** queue. After you've submitted a few orders, you should see the messages in the queue.