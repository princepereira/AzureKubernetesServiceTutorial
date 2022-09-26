# Prerequisites
- Docker service installed
- azure cli installed
- git installed
- VisualStudio Code installed
- Valid azure account and subscription


# 1. Azure Login


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

#### List all subscriptions and grep
```
PS> az account list --all --output table | findstr.exe <Subscription Pattern>
Eg: az account list --all --output table | findstr.exe Core-STACK-CoreNet-DEV
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

# 2. Create Kubernetes Cluster

#### Create an AKS cluster (Windows)
```
Probably this command take 10-30 minutes.
PS> az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --enable-addons monitoring --generate-ssh-keys --windows-admin-username <Windows Username> --vm-set-type VirtualMachineScaleSets --network-plugin azure
Eg: az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 2 --enable-addons monitoring --generate-ssh-keys --windows-admin-username azureuser --vm-set-type VirtualMachineScaleSets --network-plugin azure
Enter the password when prompts: Admin@123

If you don't specify username, then username will be "azureuser" by default and password will be some random value.
```

```
If the above commands didn't work, please use the following command to create Windows AKS Cluster.

PS> az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 1 --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --network-plugin azure
```

```
Creating AKS cluster with Network Policy (Azure NPM)
az aks create --resource-group pper_npm_rg --name aksClusterAzureNpm --node-count 1 --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --network-plugin azure --network-policy azure

Creating AKS cluster with Network Policy (Calico NPM)
az aks create --resource-group pper_npm_rg --name aksClusterCalicoNpm --node-count 1 --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --network-plugin azure --network-policy calico
```

#### Adding addtional nodes / Adding worker nodes:
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

PS> kubectl get nodes -o wide
```

# 3. Deploy application in Kubernetes


#### Create a deployment and service

```
File: sample.yaml
```
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample
  labels:
    app: sample
spec:
  replicas: 1
  template:
    metadata:
      name: sample
      labels:
        app: sample
    spec:
      nodeSelector:
        "kubernetes.io/os": windows
      containers:
      - name: sample
        image: mcr.microsoft.com/dotnet/framework/samples:aspnetapp
        resources:
          limits:
            cpu: 1
            memory: 800M
        ports:
          - containerPort: 80
  selector:
    matchLabels:
      app: sample
---
apiVersion: v1
kind: Service
metadata:
  name: sample
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
  selector:
    app: sample
```

```
PS> kubectl apply -f sample.yaml
```

```
Check the pods are ready

PS> kubectl get pods --watch
```

```
Once the pods are ready, get the Loadbalacer IP

PS> kubectl get service sample
```

```
NAME     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
sample   LoadBalancer   10.0.112.204   20.84.35.16   80:30090/TCP   5h27m
```

```
Use the external IP to access the service in browser

Browser: 20.84.35.16
```

# 4. Scale the application


#### Check the count of running pods now (1 Pod running)
```
PS> kubectl get pods
```

#### Manually scale the pod replicas (To check, run the prev command again)
```
PS> kubectl scale --replicas=5 deployment/sample
```

#### See the version of AKS cluster
PS> az aks show --resource-group myResourceGroup --name myAKSCluster --query kubernetesVersion --output table

#### Autoscale pods (Scale out if cpu percent > 50%)
```
PS> kubectl autoscale deployment sample --cpu-percent=50 --min=3 --max=10
```

#### Get the status of autoscaler
```
PS> kubectl get hpa
```

#### Manually scale AKS Nodes
```
PS> az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 3
```

# 5. Upgrade Kubernetes Cluster

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


# 6. Enable SSH Connection to the Node

#### Create an interactive shell connection to a Linux node

```
use kubectl debug to run a privileged container on your node. The following command starts a privilleged container and enter a shell.

PS> kubectl debug node/<Control Plane Node ID> -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
Eg: PS> kubectl debug node/aks-nodepool1-18811942-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
```

#### Enable port-forward for SSH in newly created debug pod

```
Open a new terminal window and use kubectl get pods to get the name of the pod started by kubectl debug.

PS> kubectl get pods

Using kubectl port-forward, you can open a connection to the deployed pod

PS> kubectl port-forward <Debug Pod ID> 2022:22
Eg: PS> kubectl port-forward node-debugger-aks-nodepool1-18811942-vmss000000-g8bbc 2022:22
```

#### SSH to the node

```
Open a new terminal and use kubectl get nodes to show the internal IP address of the Windows Server node:

PS> kubectl get nodes -o wide


Create an SSH connection to the Windows Server node using the internal IP address. The default username for AKS nodes is azureuser. Accept the prompt to continue with the connection. You are then provided with the bash prompt of your Windows Server node:

PS> ssh -o 'ProxyCommand ssh -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@<Node Internal IP>
PS> ssh -o 'ProxyCommand ssh -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@10.224.0.66
```

```
If you get any errors like below, clear entries in C:\Users\{username}\.ssh\known_hosts

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ECDSA key sent by the remote host is
SHA256:y73+VmH/a7cu3tJ82/knJ4/kgbdUFC+PxRUOQ0OxyYQ.
Please contact your system administrator.
Add correct host key in C:\\Users\\ppereira/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in C:\\Users\\ppereira/.ssh/known_hosts:3
ECDSA host key for [127.0.0.1]:2022 has changed and you have requested strict checking.
Host key verification failed.
kex_exchange_identification: Connection closed by remote host
```

To SCP logs directory in azure node:

```
PS> scp -r -o 'ProxyCommand ssh -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@<Azure Node IP>:logs/
Eg: PS> scp -r -o 'ProxyCommand ssh -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@10.224.0.33:logs/
```
```
Check all services running
CMD> sc queryex type=service state=all

Check services by anme
CMD> sc queryex type=service state=all | find /i "SERVICE_NAME:"

Get the status of specific service
CMD> sc query <Service Name>
Eg: CMD> sc query Kubeproxy
```

If you want to execute powershell commands from CMD:
```
CMD> powershell
```
```
Once the need for SSH access is done, delete the debug pod

PS> kubectl delete pod <Debug Pod ID>
Eg: PS> kubectl delete pod node-debugger-aks-nodepool1-12345678-vmss000000-bkmmx
```

# 7. Enable RDP Connection to the Windows Node
#### Query for following information
```
The commands below will query for the following information:

Cluster Resource Group (CLUSTER_RG):
PS> az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv

Virtual network (VNET_NAME):
PS> az network vnet list -g <CLUSTER_RG> --query [0].name -o tsv

Subnet name (SUBNET_NAME):
PS> az network vnet subnet list -g <CLUSTER_RG> --vnet-name <VNET_NAME> --query [0].name -o tsv

Subnet ID (SUBNET_ID):
PS> az network vnet subnet show -g <CLUSTER_RG> --vnet-name <VNET_NAME> --name <SUBNET_NAME> --query id -o tsv

```

#### Deploy a virtual machine to the same subnet as your cluster (using above queried values)

```
Create new VM
PS> az vm create  --resource-group myResourceGroup --name myVM --image win2019datacenter --admin-username azureuser --admin-password <admin-password>  --subnet <SUBNET_ID> --nic-delete-option delete --os-disk-delete-option delete --nsg "" --public-ip-address <PUBLIC_IP_ADDRESS> --query publicIpAddress -o tsv
Eg: PS> az vm create --resource-group myResourceGroup --name myRDPVM --image win2019datacenter --admin-username azureuser --admin-password Admin@123 --subnet /subscriptions/3127e2af-c391-46d9-9699-4bdb12c29012/resourceGroups/MC_AKSclustersample_samplecluster_eastus/providers/Microsoft.Network/virtualNetworks/aks-vnet-42101894/subnets/aks-subnet --nic-delete-option delete --os-disk-delete-option delete --public-ip-address "myVMPublicIP" --query publicIpAddress -o tsv

Record the public IP address of the virtual machine displayed after executing above command.
Query for the Network Security Group name (NSG_NAME):
PS> az network nsg list -g <CLUSTER_RG> --query [].name -o tsv

Create the NSG rule:
PS> az network nsg rule create --name tempRDPAccess --resource-group <CLUSTER_RG> --nsg-name <NSG_NAME> --priority 100 --destination-port-range 3389 --protocol Tcp --description "Temporary RDP access to Windows nodes"
Eg: PS> az network nsg rule create --name myVMRDPAccess --resource-group myResourceGroup --nsg-name aks-agentpool-42101894-nsg --priority 100 --destination-port-range 3389 --protocol Tcp --description "Temporary RDP access to Windows nodes"
```

#### Login to the new VM

```
RDP to the VM using the recorded public IP.
Get the internal IP of the nodes and RDP to the required node IP from within the VM

PS> kubectl get nodes -o wide

```

#### Delete the VM, public IP address and the NSG rule

```
Delete the VM
PS> az vm delete --resource-group myResourceGroup --name myRDPVM

Delete the VM public IP address
PS> az network public-ip delete --resource-group myResourceGroup --name $PUBLIC_IP_ADDRESS
Eg: PS> az network public-ip delete --resource-group myResourceGroup --name 52.146.39.153

Delete the NSG rule
PS> az network nsg rule delete --resource-group <CLUSTER_RG> --nsg-name <NSG_NAME> --name tempRDPAccess
Eg: PS> az network nsg rule delete --resource-group myResourceGroup --nsg-name aks-agentpool-42101894-nsg --name tempRDPAccess
```
