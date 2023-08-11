# product-service

This is a Spring boot app that simulates a product catalog. It is meant to be used in conjunction with the [store-front](../store-front) and [store-admin](../store-admin/) apps.

This app is a simple REST API that allows you to get a list of products, get a single product, update a product, and add a product.

Products are loaded into memory and not persisted. So if the app is restarted, the products will be reloaded.

## Running the app locally

The app does not rely on any other services, so you can run it locally without any other services running.


### Prerequisites

- [Java 17](https://learn.microsoft.com/en-us/java/openjdk/download)
- [Maven](https://maven.apache.org/download.cgi) or use the provided Maven wrapper

### Running the app

To run the app, clone the repo, open a terminal, and navigate to the `product-service` directory. Then run the following command:

```bash
./mvnw spring-boot:run
```

When the app is running, you should see output similar to the following:

```text
Initializing Spring embedded WebApplicationContext
Root WebApplicationContext: initialization completed in 1058 ms
Exposing 1 endpoint(s) beneath base path ''
Tomcat started on port(s): 3002 (http) with context path ''
Started ProductServiceApplication in 2.356 seconds (process running for 2.542)
```

Using the [`test-product-service.http`](./test-product-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.
