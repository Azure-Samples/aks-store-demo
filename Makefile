IMAGE_VERSION ?= 0.0.1-beta

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: all 
all: build load kustomize deploy ## Build all container images, load images into kind cluster, and deploy to kind cluster

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
	docker build -t order-service:$(IMAGE_VERSION) ./src/order-service
	docker build -t makeline-service:$(IMAGE_VERSION) ./src/makeline-service
	docker build -t product-service:$(IMAGE_VERSION) ./src/product-service
	docker build -t store-front:$(IMAGE_VERSION) ./src/store-front
	docker build -t store-admin:$(IMAGE_VERSION) ./src/store-admin
	docker build -t virtual-customer:$(IMAGE_VERSION) ./src/virtual-customer
	docker build -t virtual-worker:$(IMAGE_VERSION) ./src/virtual-worker

##@ Deploy to kind cluster

.PHONY: load
load: build kind ## Load all locally built containers into kind cluster
	$(KIND) load docker-image \
		order-service:$(IMAGE_VERSION) \
		makeline-service:$(IMAGE_VERSION) \
		product-service:$(IMAGE_VERSION) \
		store-front:$(IMAGE_VERSION) \
		store-admin:$(IMAGE_VERSION) \
		virtual-customer:$(IMAGE_VERSION) \
		virtual-worker:$(IMAGE_VERSION)

.PHONY: manifest ## Create kustomization.yaml and set image versions to locally built images
manifest: kustomize aks-store-all-in-one.yaml
	$(KUSTOMIZE) create --resources aks-store-all-in-one.yaml
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=order-service:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=makeline-service:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=product-service:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=store-front:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-admin=store-admin:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-customer=virtual-customer:$(IMAGE_VERSION)
	$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-worker=virtual-worker:$(IMAGE_VERSION)

.PHONY: deploy
deploy: manifest ## Deploy to cluster
	kubectl apply -k .

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
	mkdir -p $(LOCALBIN)

# tools
KUSTOMIZE ?= $(LOCALBIN)/kustomize
ENVTEST ?= $(LOCALBIN)/setup-envtest
KIND ?= $(LOCALBIN)/kind

# tool versions
KUSTOMIZE_VERSION ?= v5.1.1
KIND_VERSION ?= v0.20.0

# kustomize 
KUSTOMIZE_INSTALL_SCRIPT ?= "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
.PHONY: kustomize
kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary. If wrong version is installed, it will be removed before downloading.
$(KUSTOMIZE): $(LOCALBIN)
	@if test -x $(LOCALBIN)/kustomize && ! $(LOCALBIN)/kustomize version | grep -q $(KUSTOMIZE_VERSION); then \
		echo "$(LOCALBIN)/kustomize version is not expected $(KUSTOMIZE_VERSION). Removing it before installing."; \
		rm -rf $(LOCALBIN)/kustomize; \
	fi
	test -s $(LOCALBIN)/kustomize || { curl -Ss $(KUSTOMIZE_INSTALL_SCRIPT) | bash -s -- $(subst v,,$(KUSTOMIZE_VERSION)) $(LOCALBIN); }

.PHONY: envtest
envtest: $(ENVTEST) ## Download envtest-setup locally if necessary.
$(ENVTEST): $(LOCALBIN)
	test -s $(LOCALBIN)/setup-envtest || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

.PHONY: kind
kind: $(KIND) ## Download kind locally if necessary and create a new cluster. If wrong version is installed, it will be overwritten.
$(KIND): $(LOCALBIN)
	test -s $(LOCALBIN)/kind && $(LOCALBIN)/kind --version | grep -q $(KIND_VERSION) || \
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/kind@$(KIND_VERSION)
	@if [ `$(KIND) get clusters | wc -l` -eq 0 ]; then \
		$(KIND) create cluster; \
	fi