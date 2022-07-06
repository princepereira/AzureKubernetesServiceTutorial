# Prerequisites
- Docker service installed
- azure cli installed
- git installed
- VisualStudio Code


# 1. Build Image


#### Clone the code
```
PS> git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
```


#### Build the docker image and run the services locally using docker-compose (Run in linux container mode)
```
PS> cd azure-voting-app-redis
PS> docker-compose up -d
PS> docker images
PS> docker ps
```

#### Test application locally
```
Browser> http://localhost:8080
```

#### Cleanup the resources
```
PS> docker-compose down
```

# 2. Push images to azure container registry


#### Login to azure (Username, Password will be prompted)
```
PS> az login
```

#### Get the subscription ID
```
PS> az account show --query "id"
```

#### Set subscription
```
PS> az account set --subscription <Subscription ID>
Eg: az account set --subscription 49d938e4-f3e9-446d-b58f-7ee95eb1c134
```

#### Create Resource Group
```
PS> az group create --name myResourceGroup --location eastus
```

#### Create container registry
```
PS> az acr create --resource-group myResourceGroup --name <registry name> --sku Basic
Eg: az acr create --resource-group myResourceGroup --name ppercontainerregistry --sku Basic
```

#### To execute commands, login to container registry
```
PS> az acr login --name ppercontainerregistry
```

#### Get the login server details of container registry
```
PS> az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
```

#### Tag your container with login server details of container registry from previous command
```
PS> docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 <acrLoginServer>/azure-vote-front:v1
Eg: docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 ppercontainerregistry.azurecr.io/azure-vote-front:v1
```

#### Push images to the registry
```
PS> docker push <acrLoginServer>/azure-vote-front:v1
Eg: docker push ppercontainerregistry.azurecr.io/azure-vote-front:v1
```

#### List images in the registry
```
PS> az acr repository list --name <acrName> --output table
Eg: az acr repository list --name ppercontainerregistry.azurecr.io --output table
```

#### To see the tags for specified image
```
PS> az acr repository show-tags --name <acrName> --repository azure-vote-front --output table
Eg: az acr repository show-tags --name ppercontainerregistry.azurecr.io --repository azure-vote-front --output table
```


# 3. Create Kubernetes Cluster


#### Create an AKS cluster
```
PS> az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --generate-ssh-keys --attach-acr <acrName>
Eg: az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --generate-ssh-keys --attach-acr ppercontainerregistry
```

#### Install Kubernetes cli
```
PS> az aks install-cli
```

#### Connect to cluster using kubectl
```
PS> az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

#### Verify connection to the cluster
```
PS> kubectl get nodes
```


# 4. Deploy application in Kubernetes


#### Get the azure container registry login server details
```
PS> az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
```

#### open the manifestfile in the cloned repo from github in first section
```
PS> code azure-vote-all-in-one-redis.yaml
```

#### Replace line:60 as following (To point image to our container registry)
```
>> From > image: mcr.microsoft.com/azuredocs/azure-vote-front:v1
>> To   > ppercontainerregistry.azurecr.io/azure-vote-front:v1
```

#### Deploy the application
```
PS> kubectl apply -f azure-vote-all-in-one-redis.yaml
```

#### Wait for service to be up (Till External IP is available)
```
PS> kubectl get service azure-vote-front --watch
```

#### Use the external IP to load the application in browser
```
Browser> 20.81.69.199
```

# 5. Scale the application


#### Check the count of running pods now (1 Pod running)
```
PS> kubectl get pods
```

#### Manually scale the pod replicas (To check, run the prev command again)
```
PS> kubectl scale --replicas=5 deployment/azure-vote-front
```

#### See the version of AKS cluster
PS> az aks show --resource-group myResourceGroup --name myAKSCluster --query kubernetesVersion --output table

#### Autoscale pods (Scale out if cpu percent > 50%)
```
PS> kubectl autoscale deployment azure-vote-front --cpu-percent=50 --min=3 --max=10
```

#### Get the status of autoscaler
```
PS> kubectl get hpa
```

#### Manually scale AKS Nodes
```
PS> az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 3
```


# 6. Update the application


#### Update the application with following changes in cloned repo
```
PS> code azure-vote/azure-vote/config_file.cfg
```

From:
```
TITLE = 'Azure Voting App'
VOTE1VALUE = 'Cats'
VOTE2VALUE = 'Dogs'
SHOWHOST = 'false'
```

To:
```
# UI Configurations
TITLE = 'Azure Voting App'
VOTE1VALUE = 'Blue'
VOTE2VALUE = 'Purple'
SHOWHOST = 'false'
```

#### Update the container image
```
PS> docker-compose up --build -d
PS> docker ps
Browser> http://localhost:8080
```

#### Tag the image and push
```
PS> az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table


PS> docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 <acrLoginServer>/azure-vote-front:v2
Eg: docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 ppercontainerregistry.azurecr.io/azure-vote-front:v2

PS> docker push <acrLoginServer>/azure-vote-front:v2
Eg: docker push ppercontainerregistry.azurecr.io/azure-vote-front:v2
```

#### Update the pod with latest image
```
PS> kubectl set image deployment azure-vote-front azure-vote-front=<acrLoginServer>/azure-vote-front:v2
Eg: kubectl set image deployment azure-vote-front azure-vote-front=ppercontainerregistry.azurecr.io/azure-vote-front:v2

PS> kubectl get pods
```

#### Get the loadbalancer ip 
```
PS> kubectl get service azure-vote-front
Browser> 20.81.69.199
```

# 7. Upgrade Kubernetes Cluster

#### Get upgrade details
```
PS> az aks get-upgrades --resource-group myResourceGroup --name myAKSCluster
```

#### Upgrade cluster
```
PS> az aks upgrade --resource-group myResourceGroup --name myAKSCluster --kubernetes-version KUBERNETES_VERSION
Eg: az aks upgrade --resource-group myResourceGroup --name myAKSCluster --kubernetes-version 1.23.3
```

#### Get the events while upgrade is going on
```
PS> kubectl get events
```

#### Validate upgrade
```
PS> az aks show --resource-group myResourceGroup --name myAKSCluster --output table
```

#### Cleanup everything (Delete the resource group)
```
PS> az group delete --name myResourceGroup --yes --no-wait
```


