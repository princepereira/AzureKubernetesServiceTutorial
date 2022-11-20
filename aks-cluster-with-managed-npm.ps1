# https://msazure.visualstudio.com/CloudNativeCompute/_wiki/wikis/CloudNativeCompute.wiki/225209/Manual-Test-AKS-WS2022-Cluster?anchor=method-2---aks-supports-ws2022-by-%60%60%60aks-custom-headers-ossku%60%60%60

set -e

myLocation="eastus2euap" # Depends on you
myResourceGroup="TODO" # Depends on you
myAKSCluster=$myResourceGroup # Depends on you
myWindowsUserName="azureuser" # Recommend azureuser
myWindowsPassword="TODO" # Complex enough
myWindowsNodePool="win22" # Length <= 6

echo "creating cluster $myAKSCluster at $(date) in region $myLocation and RG $myResourceGroup"

# Update aks-preview to the latest version
az extension add --name aks-preview
az extension update --name aks-preview

az feature register --namespace Microsoft.ContainerService --name WindowsNetworkPolicyPreview
az provider register -n Microsoft.ContainerService

az group create --name $myResourceGroup --location $myLocation

az aks create \
    --resource-group $myResourceGroup \
    --name $myAKSCluster \
    --generate-ssh-keys \
    --windows-admin-username $myWindowsUserName \
    --windows-admin-password $myWindowsPassword \
    --network-plugin azure \
    --network-policy azure \
    --node-vm-size "Standard_DS2_v2" \
    --node-count 1 \
    --max-pods 100 \
    --uptime-sla

az aks nodepool add \
    --resource-group $myResourceGroup \
    --cluster-name $myAKSCluster \
    --name $myWindowsNodePool \
    --os-type Windows \
    --os-sku Windows2022 \
    --node-vm-size Standard_D4s_v3 \
    --node-count 1 \
    --max-pods 100

# uncomment below line to force pods to be scheduled on windows nodes
# az aks nodepool update --node-taints CriticalAddonsOnly=true:NoSchedule -n nodepool1 -g $myResourceGroup --cluster-name $myAKSCluster

az aks get-credentials -g $myResourceGroup -n $myAKSCluster --overwrite-existing
