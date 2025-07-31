# store-admin

This is a Vue.js app that simulates a store admin portal where users can manually process orders, and manage products. It is meant to be used in conjunction with the [product-service](../product-service/) and [makeline-service](../makeline-service). If you have access to OpenAI or Azure OpenAI API keys, you can also deploy the [ai-service](../ai-service) to help you generate product descriptions. You should also run the [virtual-customer](../virtual-customer) to simulate customers placing orders to have some order data to work with.

## Running the app locally

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)
- [Vue CLI Service](https://cli.vuejs.org/guide/cli-service.html)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [OpenAI API Key](https://beta.openai.com/docs/developer-quickstart/your-api-keys)
- [Azure OpenAI API Key](https://azure.microsoft.com/products/cognitive-services/openai-service/)

### Running the app

The app relies on the [product-service](../product-service), [makeline-service](../order-service), and optionally the [ai-service](../ai-service) along with mongodb and rabbitmq instances running. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `store-admin` directory.

If you have access to OpenAI or Azure OpenAI, open the `docker-compose.yml` file, uncomment the `ai-services` block, and add your OpenAI or Azure OpenAI credentials.

> IMPORTANT: When filling in the values, do not put the value in double-quotes.

```yaml
environment:
  - USE_AZURE_OPENAI=True # set to False if you are not using Azure OpenAI
  - AZURE_OPENAI_DEPLOYMENT_NAME= # required if using Azure OpenAI
  - AZURE_OPENAI_ENDPOINT= # required if using Azure OpenAI
  - OPENAI_API_KEY= # always required
  - OPENAI_ORG_ID= # required if using OpenAI
```

Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `store-admin` directory. Then run the following commands:

```bash
export VITE_PRODUCT_SERVICE_URL=http://localhost:3002/
export VITE_MAKELINE_SERVICE_URL=http://localhost:3001/

npm install
npm run dev
```

When the app is running, you should see output similar to the following:

```text
  App running at:
  - Local:   http://localhost:8081/
  - Network: http://192.168.0.144:8081/

  Note that the development build is not optimized.
  To create a production build, run npm run build.
```

Open a browser and navigate to `http://localhost:8081/`. You should see the store admin app running.

# Store Admin - Dynamic Theming

This store admin application supports dynamic theming based on the `COMPANY_NAME` environment variable.

## Supported Themes

- **contoso**: Contoso Pet Store theme (default) - Uses blue accents and Contoso branding
- **zava**: Zava theme - Uses black and white color scheme with Zava branding

## Environment Variables

- `COMPANY_NAME`: Set to either "Contoso" or "Zava" to determine the theme (proper casing)
- `VITE_COMPANY_NAME`: Alternative environment variable for development
- `PRODUCT_SERVICE_URL`: URL for the product service
- `MAKELINE_SERVICE_URL`: URL for the makeline service

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
docker build -t store-admin .

# Run with Zava theme
docker run -p 8081:8081 -e COMPANY_NAME=Zava store-admin

# Run with Contoso theme
docker run -p 8081:8081 -e COMPANY_NAME=Contoso store-admin
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store-admin
spec:
  template:
    spec:
      containers:
      - name: store-admin
        image: store-admin:latest
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
