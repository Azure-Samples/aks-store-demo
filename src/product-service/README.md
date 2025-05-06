# product-service

This is a Rust app that simulates a product catalog. It is meant to be used in conjunction with the [store-front](../store-front) and [store-admin](../store-admin/) apps.

This app is a simple REST API that allows you to get a list of products, get a single product, update a product, and add a product.

Products are loaded into memory and not persisted. So if the app is restarted, the products will be reloaded.

## Running the app locally

The app does not rely on any other services, so you can run it locally without any other services running.

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)

### Running the app

To run the app, clone the repo, open a terminal, and navigate to the `product-service` directory.

If you are testing the proxy for ai-service, you will need to run the ai-service container then set the `AI_SERVICE_URL` environment variable to the URL of the ai-service.

```bash
export AI_SERVICE_URL=http://ai-service:5001/
docker compose up
```

Then run the following command:

```bash
cargo run
```

When the app is running, you should see output similar to the following:

```text
    Finished dev [unoptimized + debuginfo] target(s) in 0.16s
     Running `target/debug/product-service`
Listening on http://0.0.0.0:3002
[2023-06-28T02:44:47Z INFO  actix_server::builder] starting 16 workers
[2023-06-28T02:44:47Z INFO  actix_server::server] Actix runtime found; starting in Actix runtime
```

Using the [`test-product-service.http`](./test-product-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.
