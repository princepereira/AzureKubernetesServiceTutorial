#===== Things to set in the node powershell ======#

# Enable port forwarding SSH access to the node
# PS> Add-Content $PROFILE '$ProgressPreference = "SilentlyContinue"'

$nodeIP = "10.224.0.33"
$logPath = "AKS-Logs"


mkdir $logPath
ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "rm aks* "'
ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "Remove-Item -r C:\k\debug\* -Exclude *.ps1,*.cmd,*.psm1 "'
ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command C:\k\debug\collect-windows-logs.ps1 "'
Start-Sleep 5
Write-Host "#======  Copying collected windows logs ..."
scp -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP}:aks* $logPath

