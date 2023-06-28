# virtual-worker

This is a Rust app that simulates order completion. It is meant to be used in conjunction with the [makeline-service](../makeline-service) to simulate a real-world order processing scenario.

## Running the app locally

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Running the app

This app relies on the [makeline-service](../makeline-service) and the mongodb instance running. A docker-compose file is provided to make this easy. The docker-compose file will also start the RabbitMQ, MongoDB, [order-service](../order-service), and [virtual-customer](../virtual-customer) services to simulate incoming orders. 

To run the necessary services, clone the repo, open a terminal, and navigate to the `virtual-worker` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `virtual-worker` directory. Then run the following command:

```bash
export MAKELINE_SERVICE_URL=http://localhost:3001
export ORDERS_PER_HOUR=3600
cargo run
```

The `MAKELINE_SERVICE_URL` environment variable is used to tell the virtual worker where to send the order completion messages. The `ORDERS_PER_HOUR` environment variable is used to tell the virtual worker how many orders to complete per hour. We'll set it to `3600`, which is one order per second.

When the app is running, you should see output similar to the following:

```text
Orders to process per hour: 3600
Order processing interval: 1 seconds
Sleep duration between orders: 1s
Order 86827 processed at 29.06ms with status of 1. {"orderId":"86827","customerId":"1155539187","items":[{"productId":1,"quantity":2,"price":16.143967},{"productId":3,"quantity":4,"price":78.76323},{"productId":9,"quantity":2,"price":16.52522}],"status":1}
Order 52881 processed at 1.04s with status of 1. {"orderId":"52881","customerId":"2034932567","items":[{"productId":4,"quantity":4,"price":39.27058},{"productId":8,"quantity":4,"price":69.43897}],"status":1}
Order 54344 processed at 2.06s with status of 1. {"orderId":"54344","customerId":"1707985022","items":[{"productId":2,"quantity":4,"price":85.28803},{"productId":1,"quantity":2,"price":89.426285},{"productId":1,"quantity":3,"price":39.145554},{"productId":5,"quantity":2,"price":29.205898}],"status":1}
```