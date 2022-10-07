#===== Things to set in the node powershell ======#

# Enable port forwarding SSH access to the node
# PS> Add-Content $PROFILE '$ProgressPreference = "SilentlyContinue"'
# PS> mkdir C:\LocalDumps
# PS> Reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps" /V DumpCount /t REG_DWORD /d 50 /f
# PS> Reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps" /V DumpType /t REG_DWORD /d 2 /f
# PS> Reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps" /V DumpFolder /t REG_EXPAND_SZ /d "C:\LocalDumps" /f



$count = 100000
$waitTime = 2
$nodeIP = "10.224.0.33"
$crashDumpPath = "C:\LocalDumps"
$collectLogsPath = "C:\k\debug"
$collectWindowsLogs = ".\collect-windows-logs.ps1"

function deployment() {
    Write-Host "#======  Deployment started ..."
    kubectl create -f yamls\
    Start-Sleep 5
    kubectl scale --replicas=10 deployment tcp-server
    Start-Sleep 5
    kubectl delete -f yamls\
    Write-Host "#======  Deployment cleaned up ..."
}

function startPktmon() {
    Write-Host "#======  Starting pktmon capture ..."
    ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "pktmon start --trace -p Microsoft-Windows-Host-Network-Service -l 2 -m multi-file "'
}

function stopPktmon() {
    ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "pktmon stop "'
    Write-Host "#======  Pktmon capture stopped ..."
}


startPktmon

for ($num = 1 ; $num -le $count ; $num++) {
    Write-Host "#======  Iteration : $num started ..."
    Start-Sleep $waitTime
    deployment
    if($num % 5 -ne 0) {
        continue
    }
    $dirInfo = ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "Get-ChildItem C:\LocalDumps "'
    Write-Host "#======  Directory Info : $dirInfo"
    $dirCount = ($dirInfo | Measure-Object).Count
    Write-Host "#======  Directory content count : $dirCount"
    if($dirCount -ne 0) {
        Write-Host "#======  CrashDump found ..."
        $logPath = "Logs-$num\"
        mkdir $logPath
        stopPktmon
        Write-Host "#======  Copying crash dump ..."
        scp -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP}:C:\LocalDumps\* $logPath
        Start-Sleep 5
        ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "rm C:\LocalDumps\* "'

        Write-Host "#======  Executing collect-windows-logs ..."
        ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command C:\k\debug\collect-windows-logs.ps1 "'
        Start-Sleep 5
        Write-Host "#======  Copying collected windows logs ..."
        scp -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP}:aks* $logPath
        Start-Sleep 5
        ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "rm aks* "'
        ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "Remove-Item -r C:\k\debug\* -Exclude *.ps1,*.cmd,*.psm1 "'
	  Write-Host "#======  CrashDump copy completed ..."
        scp -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP}:PktMon* $logPath
        ssh -o ConnectTimeout=300 -o 'ProxyCommand ssh -o ConnectTimeout=300 -p 2022 -W %h:%p azureuser@127.0.0.1' azureuser@${nodeIP} 'powershell -Command "rm PktMon* "'
        return
    }
}

stopPktmon

Write-Host "#======  Script completed without any issues ..."
