IMAGE_VERSION ?= 0.0.1-beta
RANDOM := $(shell bash -c 'echo $$RANDOM')
LOC_NAME ?= swedencentral
RG_NAME ?= rg-store-demo-$(RANDOM)
ACR_NAME ?= acrstoredemo$(RANDOM)
AKS_NAME ?= aks-store-demo-$(RANDOM)
AOAI_NAME ?= aoai-store-demo-$(RANDOM)
AOAI_MODEL_NAME ?= gpt-4o-mini
AOAI_MODEL_VERSION ?= 2024-07-18
AOAI_MODEL_CAPACITY ?= 8
AOAI_MODEL_SKU ?= GlobalStandard
BUILD_ORDER_SERVICE ?= false
BUILD_MAKELINE_SERVICE ?= false
BUILD_PRODUCT_SERVICE ?= false
BUILD_STORE_FRONT ?= false
BUILD_STORE_ADMIN ?= false
BUILD_VIRTUAL_CUSTOMER ?= false
BUILD_VIRTUAL_WORKER ?= false
BUILD_AI_SERVICE ?= false

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: local 
local: build load kustomize deploy ## Build all container images, load images into kind cluster, and deploy to kind cluster

.PHONY: azure
azure: provision-azure deploy-azure ## Provision Azure Resources, build all container images, push images to Azure Container Registry, and deploy to AKS cluster

.PHONY: azure-ai
azure-ai: provision-azure deploy-azure deploy-azure-ai ## Provision Azure Resources, build all container images, push images to Azure Container Registry, and deploy to AKS cluster with ai-service

##@ Build images

.PHONY: build
build: ./src/order-service/Dockerfile \
	./src/makeline-service/Dockerfile \
	./src/product-service/Dockerfile \
	./src/store-front/Dockerfile \
	./src/store-admin/Dockerfile \
	./src/virtual-customer/Dockerfile \
	./src/virtual-worker/Dockerfile \
	## Build all images
	@docker build -t order-service:$(IMAGE_VERSION) ./src/order-service
	@docker build -t makeline-service:$(IMAGE_VERSION) ./src/makeline-service
	@docker build -t product-service:$(IMAGE_VERSION) ./src/product-service
	@docker build -t store-front:$(IMAGE_VERSION) ./src/store-front
	@docker build -t store-admin:$(IMAGE_VERSION) ./src/store-admin
	@docker build -t virtual-customer:$(IMAGE_VERSION) ./src/virtual-customer
	@docker build -t virtual-worker:$(IMAGE_VERSION) ./src/virtual-worker


##@ Provision Azure Resources

.PHONY: provision-azure
provision-azure: ## Provision Azure Resources
	@echo "Provisioning Azure Resources"
	@az group create -n $(RG_NAME) -l $(LOC_NAME)
	@az acr create -n $(ACR_NAME) -g $(RG_NAME) --sku Basic
	@az aks create -n $(AKS_NAME) -g $(RG_NAME) --attach-acr $(ACR_NAME)
	@az aks get-credentials -n $(AKS_NAME) -g $(RG_NAME)
	@az cognitiveservices account create --name $(AOAI_NAME) -g $(RG_NAME) -l $(LOC_NAME) --kind OpenAI --sku S0 --custom-domain $(AOAI_NAME)
	@az cognitiveservices account deployment create -n $(AOAI_NAME) -g $(RG_NAME) --deployment-name $(AOAI_MODEL_NAME) --model-format OpenAI --model-name $(AOAI_MODEL_NAME) --model-version $(AOAI_MODEL_VERSION) --sku $(AOAI_MODEL_SKU) --capacity $(AOAI_MODEL_CAPACITY)

	@if [ "$(BUILD_ORDER_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t order-service:$(IMAGE_VERSION) ./src/order-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/order-service:latest --image order-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_MAKELINE_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t makeline-service:$(IMAGE_VERSION) ./src/makeline-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/makeline-service:latest --image makeline-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_PRODUCT_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t product-service:$(IMAGE_VERSION) ./src/product-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/product-service:latest --image product-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_STORE_FRONT)" = true ]; then \
		az acr build -r $(ACR_NAME) -t store-front:$(IMAGE_VERSION) ./src/store-front; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/store-front:latest --image store-front:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_STORE_ADMIN)" = true ]; then \
		az acr build -r $(ACR_NAME) -t store-admin:$(IMAGE_VERSION) ./src/store-admin; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/store-admin:latest --image store-admin:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_VIRTUAL_CUSTOMER)" = true ]; then \
		az acr build -r $(ACR_NAME) -t virtual-customer:$(IMAGE_VERSION) ./src/virtual-customer; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/virtual-customer:latest --image virtual-customer:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_VIRTUAL_WORKER)" = true ]; then \
		az acr build -r $(ACR_NAME) -t virtual-worker:$(IMAGE_VERSION) ./src/virtual-worker; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/virtual-worker:latest --image virtual-worker:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_AI_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t ai-service:$(IMAGE_VERSION) ./src/ai-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/ai-service:latest --image ai-service:$(IMAGE_VERSION); \
	fi

.PHONY: deploy-azure
deploy-azure: kustomize aks-store-all-in-one.yaml ## Deploy to AKS cluster
	@$(KUSTOMIZE) create --resources aks-store-all-in-one.yaml
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=$(ACR_NAME).azurecr.io/order-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=$(ACR_NAME).azurecr.io/makeline-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=$(ACR_NAME).azurecr.io/product-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=$(ACR_NAME).azurecr.io/store-front:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-admin=$(ACR_NAME).azurecr.io/store-admin:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-customer=$(ACR_NAME).azurecr.io/virtual-customer:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-worker=$(ACR_NAME).azurecr.io/virtual-worker:$(IMAGE_VERSION)
	@kubectl apply -k .

.PHONY: deploy-azure-ai
deploy-azure-ai: deploy-azure kustomize ai-service.yaml ## Deploy ai-service to AKS cluster
	@# Remove existing kustomization.yaml and .env if they exist
	@rm -f kustomization.yaml .env

	@# Create kustomization.yaml and .env
	@$(KUSTOMIZE) create --resources ai-service.yaml

	@# Set image version
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/ai-service=$(ACR_NAME).azurecr.io/ai-service:$(IMAGE_VERSION)

	@# Set environment variables
	@echo "USE_AZURE_OPENAI=True" > .env
	@echo "USE_AZURE_AD=False" >> .env
	@echo "AZURE_OPENAI_DEPLOYMENT_NAME=$(AOAI_MODEL_NAME)" >> .env
	@echo "AZURE_OPENAI_ENDPOINT=$$(az cognitiveservices account show -n $(AOAI_NAME) -g $(RG_NAME) --query properties.endpoint -o tsv)" >> .env
	@echo "OPENAI_API_KEY=$$(az cognitiveservices account keys list -n $(AOAI_NAME) -g $(RG_NAME) --query key1 -o tsv)" >> .env

	@# Add configMapGenerator and patches to kustomization.yaml
	@echo "configMapGenerator:\n- name: ai-service-configmap\n  envs:\n  - .env" >> kustomization.yaml

	@# Add patches to kustomization.yaml
	@echo "patches:\n- patch: |-\n    - op: remove\n      path: \"/spec/template/spec/containers/0/env\"\n    - op: add\n      path: \"/spec/template/spec/containers/0/envFrom\"\n      value:\n      - configMapRef:\n          name: ai-service-configmap\n  target:\n    kind: Deployment\n    name: ai-service" >> kustomization.yaml

	@# Deploy to AKS cluster
	@$(KUSTOMIZE) build . | kubectl apply -f -


.PHONY: clean-azure
clean-azure: ## Delete kind cluster and kustomization.yaml
	@az group delete -n $(RG_NAME) -y --no-wait
	@rm -f kustomization.yaml
	@rm -rf $(LOCALBIN)

##@ Deploy to kind cluster

.PHONY: load
load: build kind ## Load all locally built containers into kind cluster
	@$(KIND) load docker-image \
		order-service:$(IMAGE_VERSION) \
		makeline-service:$(IMAGE_VERSION) \
		product-service:$(IMAGE_VERSION) \
		store-front:$(IMAGE_VERSION) \
		store-admin:$(IMAGE_VERSION) \
		virtual-customer:$(IMAGE_VERSION) \
		virtual-worker:$(IMAGE_VERSION)

.PHONY: manifest ## Create kustomization.yaml and set image versions to locally built images
manifest: kustomize aks-store-all-in-one.yaml
	@$(KUSTOMIZE) create --resources aks-store-all-in-one.yaml
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=order-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=makeline-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=product-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=store-front:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-admin=store-admin:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-customer=virtual-customer:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-worker=virtual-worker:$(IMAGE_VERSION)

.PHONY: deploy
deploy: manifest ## Deploy to cluster
	@kubectl apply -k .

.PHONY: clean 
clean: ## Delete kind cluster and kustomization.yaml
	@if [ `kind get clusters | wc -l` -gt 0 ]; then \
		kind delete cluster; \
	fi
	@rm -f kustomization.yaml
	@rm -rf $(LOCALBIN)

##@ Build Dependencies

LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	@mkdir -p $(LOCALBIN)

# tools
KUSTOMIZE ?= $(LOCALBIN)/kustomize
ENVTEST ?= $(LOCALBIN)/setup-envtest
KIND ?= $(LOCALBIN)/kind

# tool versions
KUSTOMIZE_VERSION ?= v5.4.3
KIND_VERSION ?= v0.23.0

# kustomize 
KUSTOMIZE_INSTALL_SCRIPT ?= "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
.PHONY: kustomize
kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary. If wrong version is installed, it will be removed before downloading.
$(KUSTOMIZE): $(LOCALBIN)
	@if test -x $(LOCALBIN)/kustomize && ! $(LOCALBIN)/kustomize version | grep -q $(KUSTOMIZE_VERSION); then \
		echo "$(LOCALBIN)/kustomize version is not expected $(KUSTOMIZE_VERSION). Removing it before installing."; \
		rm -rf $(LOCALBIN)/kustomize; \
	fi
	@test -s $(LOCALBIN)/kustomize || { curl -Ss $(KUSTOMIZE_INSTALL_SCRIPT) | bash -s -- $(subst v,,$(KUSTOMIZE_VERSION)) $(LOCALBIN); }

.PHONY: envtest
envtest: $(ENVTEST) ## Download envtest-setup locally if necessary.
$(ENVTEST): $(LOCALBIN)
	@test -s $(LOCALBIN)/setup-envtest || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

.PHONY: kind
kind: $(KIND) ## Download kind locally if necessary and create a new cluster. If wrong version is installed, it will be overwritten.
$(KIND): $(LOCALBIN)
	@test -s $(LOCALBIN)/kind && $(LOCALBIN)/kind --version | grep -q $(KIND_VERSION) || \
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/kind@$(KIND_VERSION)
	@if [ `$(KIND) get clusters | wc -l` -eq 0 ]; then \
		$(KIND) create cluster; \
	fi