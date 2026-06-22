# Copilot Instructions for aks-store-demo

## Architecture

This is a polyglot microservices demo app for Azure Kubernetes Service (AKS). Services communicate via RabbitMQ (order queue) and persist data in DocumentDB (MongoDB-compatible).

**Services and their tech stacks:**

| Service | Language/Framework | Port | Purpose |
|---------|-------------------|------|---------|
| order-service | Node.js / Fastify | 3000 | Accepts orders, publishes to RabbitMQ |
| makeline-service | Go / Gin | 3001 | Consumes orders from queue, marks complete |
| product-service | Rust / Actix-web | 3002 | CRUD for product catalog |
| store-front | Vue 3 / Vite / TypeScript | 8080 | Customer-facing web app |
| store-admin | Vue 3 / Vite / TypeScript | 8081 | Employee web app for order/product management |
| ai-service | Python / FastAPI | 5001 | Generative AI for product descriptions/images |
| virtual-customer | Rust | - | Simulates order creation |
| virtual-worker | Rust | - | Simulates order completion |

**Infrastructure dependencies:** RabbitMQ (message queue), DocumentDB/MongoDB (persistence). Azure Service Bus and Cosmos DB are supported as cloud alternatives.

**Data flow:** store-front -> order-service -> RabbitMQ -> makeline-service -> DocumentDB. The product-service reads/writes products directly to DocumentDB.

## Build & Run

### Full stack (Docker Compose)

```bash
docker compose up --build
```

### Individual services

Each service has its own `Dockerfile` and most have a `docker-compose.yml` in their directory for isolated development.

```bash
# order-service
cd src/order-service && npm install && npm run dev

# makeline-service
cd src/makeline-service && go run .

# product-service
cd src/product-service && cargo run

# store-front or store-admin
cd src/store-front && npm install && npm run dev

# ai-service
cd src/ai-service && pip install -r requirements.txt && uvicorn main:app --reload --port 5001
```

### Build all container images

```bash
make build  # builds all service images
```

## Testing

### Vue frontends (store-front, store-admin)

```bash
cd src/store-front
npm run test:unit           # Vitest unit tests
npm run test:e2e            # Playwright e2e tests
npm run lint                # oxlint + eslint (with --fix)
npm run type-check          # vue-tsc
```

### order-service

```bash
cd src/order-service
npm test                    # tap test runner
```

### product-service

```bash
cd src/product-service
cargo test
```

### ai-service

```bash
cd src/ai-service
pytest
pylint main.py routers/
```

### End-to-end tests (root-level)

```bash
cd tests
npm install
npx playwright test                              # all e2e tests
npx playwright test e2e/store-front/basic.spec.ts  # single test file
npx playwright test --headed                     # with browser UI
```

These tests require the app to be running and need configuration via environment variables (see `tests/TEST_CONFIG.md`).

## Deployment

### Azure Developer CLI (azd)

```bash
azd up    # provisions infrastructure and deploys
```

Infrastructure is defined in `infra/terraform` (default) or `infra/bicep`. The `azure.yaml` file configures the azd workflow with hooks in `azd-hooks/`.

### Kubernetes manifests

- `aks-store-quickstart.yaml` - minimal deployment
- `aks-store-all-in-one.yaml` - full deployment with all services
- `charts/aks-store-demo/` - Helm chart
- `kustomize/` - Kustomize overlays

### Makefile targets

```bash
make local    # build images, load into kind, deploy via kustomize
make azure    # provision Azure resources and deploy
make help     # list all targets
```

## Conventions

- Each service is fully self-contained in `src/<service-name>/` with its own Dockerfile, dependencies, and README.
- Vue frontends use Composition API with `<script setup>`, Pinia for state, and Vue Router.
- Vue frontends use a two-tier linting pipeline: oxlint (fast, correctness rules) then eslint.
- Prettier is configured at root (`.prettierrc.json`) and used by both Vue apps.
- HTTP test files (`test-*.http`) exist in each backend service directory for manual API testing.
- Environment variables configure service connections (see `.env` files and docker-compose).
- The `ai-service` is optional; the app functions without it.
