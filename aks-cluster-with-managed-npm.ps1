myResourceGroup="pperRgAzNpm"
$myResourceGroup="pperRgAzNpm"
$myLocation="eastus2euap"
$myAKSCluster="pperAksAzNpm"
$myWindowsNodePool="win22" # Length <= 6
$subscription="0709bd7a-8383-4e1d-98c8-f81d1b3443fc"

az login

Write-Host "Set subscription ..."
az account set --subscription $subscription

Write-Host "Add and update preview ..."
az extension add --name aks-preview
az extension update --name aks-preview
az feature register --namespace Microsoft.ContainerService --name WindowsNetworkPolicyPreview
az provider register -n Microsoft.ContainerService

Write-Host "Create resource group ..."
az group create --name $myResourceGroup --location $myLocation

Write-Host "Create cluster ..."
az aks create --resource-group $myResourceGroup --name $myAKSCluster --node-count 1 --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --network-plugin azure --network-policy azure --node-vm-size "Standard_DS2_v2" --max-pods 100 --uptime-sla

Write-Host "Adding node pool ..."
az aks nodepool add --resource-group $myResourceGroup --cluster-name $myAKSCluster --name $myWindowsNodePool --node-count 1 --os-type Windows --os-sku Windows2022 --node-vm-size Standard_D4s_v3 --max-pods 100az 

# uncomment below line to force pods to be scheduled on windows nodes
# az aks nodepool update --node-taints CriticalAddonsOnly=true:NoSchedule -n nodepool1 -g $myResourceGroup --cluster-name $myAKSCluster

Write-Host "Retrieving credentials ..."
aks get-credentials -g $myResourceGroup -n $myAKSCluster
