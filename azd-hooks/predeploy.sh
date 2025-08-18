#!/usr/bin/env sh

##########################################################
# Ensure Helm and Kustomize support is enabled  
##########################################################
azd config set alpha.aks.helm on
azd config set alpha.aks.kustomize on

# Check kubelogin and install if not exists
##########################################################
if ! command -v kubelogin >/dev/null 2>&1; then
  echo "kubelogin could not be found. Installing kubelogin..."
  az aks install-cli
fi

##########################################################
# Create the custom-values.yaml file
##########################################################
cat << EOF > custom-values.yaml
namespace: ${AZURE_AKS_NAMESPACE}
EOF

###########################################################
# Add Azure Managed Identity and set to use AzureAD auth 
###########################################################
if [ -n "${AZURE_IDENTITY_CLIENT_ID}" ] && [ -n "${AZURE_IDENTITY_NAME}" ]; then
  cat << EOF >> custom-values.yaml
useAzureAd: true
managedIdentityName: ${AZURE_IDENTITY_NAME}
managedIdentityClientId: ${AZURE_IDENTITY_CLIENT_ID}
EOF
fi

##########################################################
# Add base images
##########################################################
cat << EOF >> custom-values.yaml
productService:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/product-service
storeAdmin:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/store-admin
storeFront:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/store-front
virtualCustomer:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/virtual-customer
virtualWorker:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/virtual-worker
EOF

###########################################################
# Add ai-service if Azure OpenAI endpoint is provided
###########################################################

if [ -n "${AZURE_OPENAI_ENDPOINT}" ]; then
  cat << EOF >> custom-values.yaml
aiService:
  image:
      repository: ${SOURCE_REGISTRY}/aks-store-demo/ai-service
  create: true
  modelDeploymentName: ${AZURE_OPENAI_MODEL_NAME}
  openAiEndpoint: ${AZURE_OPENAI_ENDPOINT}
  useAzureOpenAi: true
EOF

  # If DALL-E model endpoint and name exists
  if [ -n "${AZURE_OPENAI_DALL_E_ENDPOINT}" ] && [ -n "${AZURE_OPENAI_DALL_E_MODEL_NAME}" ]; then
    cat << EOF >> custom-values.yaml
  openAiDalleEndpoint: ${AZURE_OPENAI_DALL_E_ENDPOINT}
  openAiDalleModelName: ${AZURE_OPENAI_DALL_E_MODEL_NAME}
EOF
  fi
fi

###########################################################
# Add order-service
###########################################################

cat << EOF >> custom-values.yaml
orderService:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/order-service
EOF

# Add Azure Service Bus to order-service if provided
if [ -n "${AZURE_SERVICE_BUS_HOST}" ]; then
  cat << EOF >> custom-values.yaml
  queueHost: ${AZURE_SERVICE_BUS_HOST}
EOF
fi

###########################################################
# Add makeline-service
###########################################################

cat << EOF >> custom-values.yaml
makelineService:
  image:
    repository: ${SOURCE_REGISTRY}/aks-store-demo/makeline-service
EOF

# Add Azure Service Bus to makeline-service if provided
if [ -n "${AZURE_SERVICE_BUS_HOST}" ]; then
  cat << EOF >> custom-values.yaml
  orderQueueHost: ${AZURE_SERVICE_BUS_HOST}
EOF
fi

# Add Azure Cosmos DB to makeline-service if provided
if [ -n "${AZURE_COSMOS_DATABASE_URI}" ]; then
  cat << EOF >> custom-values.yaml
  orderDBApi: ${AZURE_DATABASE_API}
  orderDBUri: ${AZURE_COSMOS_DATABASE_URI}
EOF
fi

###########################################################
# Do not deploy RabbitMQ when using Azure Service Bus
###########################################################
if [ -n "${AZURE_SERVICE_BUS_HOST}" ]; then
  cat << EOF >> custom-values.yaml
useRabbitMQ: false
EOF
fi

###########################################################
# Do not deploy MongoDB when using Azure Cosmos DB
###########################################################
if [ -n "${AZURE_COSMOS_DATABASE_URI}" ]; then
  cat << EOF >> custom-values.yaml
useMongoDB: false
EOF
fi
