# Store Front - Dynamic Theming

This store front application supports dynamic theming based on the `COMPANY_NAME` environment variable.

## Supported Themes

- **contoso**: Contoso Pet Store theme (default) - Uses blue accents and Contoso branding
- **zava**: Zava theme - Uses black and white color scheme with Zava branding

## Environment Variables

- `COMPANY_NAME`: Set to either "Contoso" or "Zava" to determine the theme (proper casing)
- `VITE_COMPANY_NAME`: Alternative environment variable for development
- `PRODUCT_SERVICE_URL`: URL for the product service
- `ORDER_SERVICE_URL`: URL for the order service

## Usage

### Development

```bash
# Use Contoso theme (default)
npm run dev

# Use Zava theme
COMPANY_NAME=Zava npm run dev

# Or using Vite environment variable
VITE_COMPANY_NAME=Zava npm run dev
```

### Docker

```bash
# Build with Contoso theme
docker build -t store-front .

# Run with Zava theme
docker run -p 8080:8080 -e COMPANY_NAME=Zava store-front

# Run with Contoso theme
docker run -p 8080:8080 -e COMPANY_NAME=Contoso store-front
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store-front
spec:
  template:
    spec:
      containers:
      - name: store-front
        image: store-front:latest
        env:
        - name: COMPANY_NAME
          value: "Zava"  # or "Contoso"
```

## Theme Configuration

Themes are configured in `src/config/themes.ts`. Each theme defines:

- Logo image and alt text
- Color scheme (primary, secondary, accent colors, etc.)
- Company name
- Page title

The theme system uses CSS custom properties to dynamically apply colors throughout the application.

### Supported Values

The `COMPANY_NAME` environment variable accepts the following values:
- `Contoso` - Applies the Contoso Pet Store theme
- `Zava` - Applies the Zava theme

Values are case-sensitive and should use proper capitalization as shown above. The system will convert these to lowercase internally to match theme configuration keys.

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
export COMPANY_NAME=Zava  # or Contoso

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

