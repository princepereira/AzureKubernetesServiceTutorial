# Prerequisites
- Docker service installed
- azure cli installed
- git installed
- VisualStudio Code installed
- Valid azure account and subscription


# 1. Build Image


#### Clone the application code
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

#### Pull a new container
```
If you don't want to build image, you can also pull the image.
PS> mcr.microsoft.com/azuredocs/azure-vote-front:v1
```

# 2. Push images to azure container registry


#### Login to azure (Username, Password will be prompted)
```
PS> az login
```

```
If the above command is not working, use the below command
PS> az login --use-device-code

A device code will be generated. Use the device code and submit it in the following link in browser.
Browser> https://microsoft.com/devicelogin
```

```
If you face issues with multi factor authentication, use following command to login:
PS> az login --tenant <Tenant ID>
```

#### Get the subscription ID
```
PS> az account show --query "id"
```

#### Set subscription
```
PS> az account set --subscription <Subscription ID>
Eg: az account set --subscription 49d938e4-f3e9-446d-b58f-7aa95eb1c123
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

#### Create an AKS cluster (Windows)
```
PS> az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --enable-addons monitoring --generate-ssh-keys --windows-admin-username <Windows Username> --vm-set-type VirtualMachineScaleSets --network-plugin azure
Eg: az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --enable-addons monitoring --generate-ssh-keys --windows-admin-username azureuser --vm-set-type VirtualMachineScaleSets --network-plugin azure
Enter the password when prompts: Admin@123

If you don't specify username, then username will be "azureuser" by default and password will be some random value.
```

#### Adding addtional nodes:
```
PS> az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --os-type Windows --name npwin --node-count 1
```

#### Install the aks-preview extension
```
Install the aks-preview extension

PS> az extension add --name aks-preview
```

```
Update the extension to make sure you have the latest version installed

PS> az extension update --name aks-preview
```

##### Register the AKSWindows2022Preview preview feature
```
Following commands take few minutes

PS> az feature register --namespace "Microsoft.ContainerService" --name "AKSWindows2022Preview"
```

```
See the update of previous command

PS> az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKSWindows2022Preview')].{Name:name,State:properties.state}"
```

```
When ready, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command:

PS> az provider register --namespace Microsoft.ContainerService
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

#### Delete the cluster
```
PS> az aks delete --resource-group myResourceGroup --name myAKSCluster
```

#### Cleanup everything (Delete the resource group)
```
PS> az group delete --name myResourceGroup --yes --no-wait
```

# 8. SSH access to VM/AKS Node

#### Find the cluster resource group 

```
PS> az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv
```

#### Find the scale set name
```
PS> az vmss list --resource-group <cluster resource group> --query [0].name -o tsv
Eg: az vmss list --resource-group MC_myResourceGroup_myAKSCluster_eastus --query [0].name -o tsv
```

#### Copy the SSH keys from local to the node
```
PS> az vmss extension set --resource-group <cluster resource group> --vmss-name <scale set name> --name VMAccessForLinux --publisher Microsoft.OSExtensions --version 1.4 --protected-settings '{"username":"azureuser","ssh_key":"$(cat ~/.ssh/id_rsa)"}'

Eg: az vmss extension set --resource-group MC_myResourceGroup_myAKSCluster_eastus --vmss-name aks-nodepool1-20559094-vmss --name VMAccessForLinux --publisher Microsoft.OSTCExtensions --version 1.4 --protected-settings "{'username':'azureuser', 'ssh_key':'$(cat ~/.ssh/id_rsa.pub)'}"
```

#### Show extensions
```
PS> az vmss extension show --name VMAccessForLinux --resource-group MC_myResourceGroup_myAKSCluster_eastus --vmss-name aks-nodepool1-20559094-vmss
```

#### Update instances
```
PS> az vmss update-instances --instance-ids ‘*’ --resource-group $CLUSTER_RESOURCE_GROUP --name $SCALE_SET_NAME
Eg: az vmss update-instances --instance-ids ‘*’ --resource-group MC_myResourceGroup_myAKSCluster_eastus --name aks-nodepool1-20559094-vmss
```

#### Start a minimal container to act as a jump station (This will enter the terminal of container)
```
PS> kubectl run -it aks-ssh --image=debian
```

#### Install openssh client inside the container
```
Docker> apt-get update && apt-get install openssh-client -y
```

#### Copy the ssh keys from a new terminal
```
PS> cd ~/.ssh
PS> kubectl cp .\id_rsa aks-ssh:id_rsa
```

#### Check the key is copied to container
```
Docker> ls
```
