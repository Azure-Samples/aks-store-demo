# virtual-customer

This is a Rust app that simulates order submission. It is meant to be used in conjunction with the [order-service](../makeline-service) to simulate customers submitting orders over a period of time.

## Running the app locally

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Running the app

This app relies on the [order-service](../order-service) and the rabbitmq instance running. A docker-compose file is provided to make this easy. 

To run the necessary services, clone the repo, open a terminal, and navigate to the `virtual-customer` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `virtual-customer` directory. Then run the following command:

```bash
export ORDER_SERVICE_URL=http://localhost:3000/
export ORDERS_PER_HOUR=3600
cargo run
```

The `ORDER_SERVICE_URL` environment variable is used to tell the virtual customer where to send the order messages. The `ORDERS_PER_HOUR` environment variable is used to tell the virtual customer how many orders to send per hour. We'll set it to `3600`, which is one order per second.

When the app is running, you should see output similar to the following:

```text
Orders to submit per hour: 3600
Order submission interval: 1 seconds
Sleep duration between orders: 1s
Order 1 sent at 14.10ms with status of 201 Created. {"customerId":"1358326708","items":[{"productId":4,"quantity":3,"price":67.659355},{"productId":9,"quantity":2,"price":21.281868},{"productId":9,"quantity":1,"price":51.21942}]}
Order 2 sent at 1.03s with status of 201 Created. {"customerId":"1888758279","items":[{"productId":8,"quantity":4,"price":56.293404},{"productId":7,"quantity":4,"price":58.618687},{"productId":4,"quantity":2,"price":19.681084}]}
```