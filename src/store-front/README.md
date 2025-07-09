# store-front

This is a Vue.js app that simulates a store front. It is meant to be used in conjunction with the [product-service](../product-service/) and [order-service](../order-service). The app is extremely simple in that it only has a cart and a order submission button. When the order submission button is clicked, the cart is emptied and the order is sent to the order service. Currently there is no order checkout pages to collect any customer information.

## Running the app locally

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)
- [Vue CLI Service](https://cli.vuejs.org/guide/cli-service.html)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Running the app

The app relies on the [product-service](../product-service) and the [order-service](../order-service) and the rabbitmq instance running. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `store-front` directory. Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `store-front` directory. Then run the following commands:

```bash
export VITE_PRODUCT_SERVICE_URL=http://localhost:3002/
export VITE_ORDER_SERVICE_URL=http://localhost:3000/

npm install
npm run dev
```

When the app is running, you should see output similar to the following:

```text
  App running at:
  - Local:   http://localhost:8080/
  - Network: http://192.168.0.144:8080/

  Note that the development build is not optimized.
  To create a production build, run npm run build.
```

Open a browser and navigate to `http://localhost:8080/`. You should see the store front app running.
