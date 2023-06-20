## Getting Started

#### Deploy AKS (Azure CLI)

```bash

          #echo "version=$(echo ${GITHUB_SHA} | cut -c1-7)" >> $GITHUB_STATE
          #echo "created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> $GITHUB_STATE
          #echo "project=ai-service" >> $GITHUB_STATE
          #echo "image=ai-service" >> $GITHUB_STATE
          #echo "repository=ghcr.io/azure-samples/aks-store-demo" >> $GITHUB_STATE

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

> Note: You can build images with docker or "acr build"

```bash
# create an ACR instance and attach for testing
ACR_NAME='myacr'
az acr create --resource-group $RG --name $ACR_NAME --sku Standard
az acr login --name $ACR_NAME
az aks update -n $AKS_CLUSTER -g $RG --attach-acr $ACR_NAME

# order-service
cd src/order-service

docker build -t aks-store-demo/order-service:0.20 .
docker tag aks-store-demo/order-service:0.20 myacr.azurecr.io/aks-store-demo/order-service:0.20
docker push myacr.azurecr.io/aks-store-demo/order-service:0.20

az acr build -t aks-store-demo/order-service:0.20 -r $ACR_NAME .

# store-front
cd src/store-front

docker build -t aks-store-demo/store-front:0.20 .
docker tag aks-store-demo/store-front:0.20 myacr.azurecr.io/aks-store-demo/store-front:0.20
docker push myacr.azurecr.io/aks-store-demo/store-front:0.20

az acr build -t aks-store-demo/store-front:0.20 -r $ACR_NAME .

# virtual-worker
cd src/virtual-worker

docker build -t aks-store-demo/virtual-worker:0.20 .
docker tag aks-store-demo/virtual-worker:0.20 myacr.azurecr.io/aks-store-demo/virtual-worker:0.20
docker push myacr.azurecr.io/aks-store-demo/virtual-worker:0.20

az acr build -t aks-store-demo/virtual-worker:0.20 -r $ACR_NAME .

```

#### Deploy the application

```bash

# you must edit this YAML and replace your ACR name in the images for each container

kubectl apply -f aks-store-all-in-one.yaml
```

#### Test the application

```bash

# get YOUR public IP for the store-front and order-service
# you can bring up the store-front using your browser
# curl the order-service to test orders as shown below

kubectl get svc

NAME             TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                          AGE
kubernetes       ClusterIP      10.0.0.1       <none>          443/TCP                          23h
mongodb          LoadBalancer   10.0.41.74     192.168.1.10    27017:32572/TCP                  18h
order-service    LoadBalancer   10.0.39.248    192.168.1.11    3000:31753/TCP                   18h
rabbitmq         LoadBalancer   10.0.11.217    192.168.1.12    5672:32333/TCP,15672:31254/TCP   18h
store-front      LoadBalancer   10.0.214.194   192.168.1.13    8080:30073/TCP                   18h
virtual-worker   LoadBalancer   10.0.181.99    192.168.1.14    4001:32627/TCP                   18h

curl -X POST -H "Content-Type: application/json" -d '{"customerId":"1234567890","items":[{"product":1,"quantity":1,"price":10},{"product":2,"quantity":2,"price":20}]}' http://192.168.1.11:3000


```



