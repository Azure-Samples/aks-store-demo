## Getting Started

#### Deploy AKS (Azure CLI)

```bash
RG='aks-quickstart'
LOCATION='eastus'
AKS_CLUSTER='briar-aks'

az group create --name $RG --location $LOCATION

az aks create -g $RG -n $AKS_CLUSTER --enable-managed-identity --node-count 1 --enable-addons monitoring --enable-msi-auth-for-monitoring  --generate-ssh-keys

az aks get-credentials --resource-group $RG --name $AKS_CLUSTER

kubectl get pod -A
```

#### Build container images (for testing)

> Note: This step will not be needed in the Quickstart. Images will be built in GH Action and pushed to MCR

```bash
# create an ACR instance and attach for testing
ACR_NAME='myacr'
az acr create --resource-group $RG --name $ACR_NAME --sku Standard
az acr login --name $ACR_NAME
az aks update -n $AKS_CLUSTER -g $RG --attach-acr $ACR_NAME

# order-service
cd src/order-service

docker build -t aks-store-demo/order-service:0.10 .
docker tag aks-store-demo/order-service:0.10 myacr.azurecr.io/aks-store-demo/order-service:0.10
docker push myacr.azurecr.io/aks-store-demo/order-service:0.10

az acr build -t aks-store-demo/order-service:0.20 -r $ACR_NAME .

# store-front
cd src/store-front

docker build -t aks-store-demo/store-front:0.10 .
docker tag aks-store-demo/store-front:0.10 myacr.azurecr.io/aks-store-demo/store-front:0.10
docker push myacr.azurecr.io/aks-store-demo/store-front:0.10

az acr build -t aks-store-demo/store-front:0.20 -r $ACR_NAME .

# virtual-worker
cd src/virtual-worker

docker build -t aks-store-demo/virtual-worker:0.10 .
docker tag aks-store-demo/virtual-worker:0.10 myacr.azurecr.io/aks-store-demo/virtual-worker:0.10
docker push myacr.azurecr.io/aks-store-demo/virtual-worker:0.10

az acr build -t aks-store-demo/virtual-worker:0.20 -r $ACR_NAME .

```

#### Deploy the application

```bash
kubectl apply -f aks-store-all-in-one.yaml
```

#### Test the application





