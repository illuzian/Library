# Runs a PowerShell or shell script on all machines in a csv file with column name "Name"
param (

    $LinuxScript = '',
    $WindowsScript = '',
    $SaveFolder = '',
    $SlashType = '\',
    $VMListFile = '',
    $VerboseOut = $true,
    $MonitorSleepSeconds = 5,
    $TenantId = '',
    $DelayMin = 15,
    $DelayMax = 30
)

$output = if ($VerboseOut) { 'Out-Default' } else { 'Out-Null' }

$VMList = import-csv -path $VMListFile 


if (!(Test-Path $SaveFolder)) {
    Write-Output "Target folder did not exist. Attempting to create."
    New-Item -ErrorAction Stop -ItemType Directory -Force -Path $SaveFolder | & $output
}

$Subs = Get-AzSubscription 
$ScriptTS = Get-Date -Format 'yyyyMMddHHmm'
$SaveFolder += $SlashType + $ScriptTS
New-Item -ErrorAction Stop -ItemType Directory -Force -Path $SaveFolder | & $output
$Global:ScanSaveFolder = $SaveFolder

$Script:FoundVMs = @() 
if ($global:ScanJobs) {
    New-Variable -Name "ScanJobsOld_$ScriptTS" -Value $global:ScanJobs -Scope Global
    Remove-Variable -Name "ScanJobs" -Scope Global
}
New-Variable -Scope Global -Name "ScanJobs" -Value @() 


ForEach ($Sub in $Subs) {
    $Sub | Set-AzContext  -Scope CurrentUser
    $VMs = get-azvm  | Where-Object { $_.Name -in $VMList.Name }
    $Script:FoundVMs += @($VMs.Name)
    foreach ($VM in $VMs) {
        $SavePath = "$SaveFolder$SlashType$($VM.Name).out"

            $global:ScanJobs += Start-Job -Name "$($VM.Name)$ScriptTS" -ArgumentList $SavePath,$VM,$WindowsScript,$LinuxScript,$Sub,$VM.StorageProfile.OsDisk.OSType,$TenantId,$DelayMin,$DelayMax  -ScriptBlock {
                $TGTSavePath = $args[0]
                $TGTVM = $args[1]
                $TGTWindowsScript = $args[2]
                $TGTLinuxScript = $args[3]
                $TGTSub = $args[4]
                $TGTOS = $args[5]
                $TGTTenant = $args[6]
                $TGTDelayMin = $args[7]
                $TGTDelayMax = $args[8]
                
                $StartDelay = get-random  -Minimum $TGTDelayMin -Maximum $TGTDelayMax
                Write-Output "Sleeping $StartDelay before execution."
                Start-Sleep -Seconds $StartDelay

                
                if ($TGTOS -like '*windows*' -and $TGTWindowsScript) {
                    $RunScript = $TGTWindowsScript
                    $CommandType = 'RunPowerShellScript'
                    Write-output 'Got Windows script'
                } elseif ($TGTOS -like '*linux*' -and $TGTLinuxScript ) {
                    $RunScript = $TGTLinuxScript
                    $CommandType = 'RunShellScript'
                    Write-output 'Got Linux script'
                } else {continue}

                $TGTVM.id -match '\/subscriptions\/([^\/]*)\/resourceGroups\/([^\/]*)\/'
                $sub = $matches[1]
                $rg = $matches[2]

                Set-AzContext -SubscriptionId "$sub" -TenantId "$TGTTenant"
                # Get-AzResourceGroup -ResourceGroupName "$rg"

                Write-Output "$($TGTVM.Name) to execute $RunScript of type $CommandType in rg $rg of sub $sub to path $TGTSavePath"

                Write-Output $TGTVM.Name | Tee-Object -Append -FilePath $TGTSavePath
                Invoke-AzVMRunCommand -ResourceGroupName $rg -VMName $TGTVM.Name -CommandId $CommandType -ScriptPath $RunScript 2>&1 | Tee-Object -Append -FilePath $TGTSavePath


            } 
            
        }
    }


    

Write-Output 'Jobs saved in $ScanJobs'
$Global:ScanJobs
$ComparedFileName = 'missing.out'
$Script:MissingServers = @()
ForEach ($TargetVM in $VMList.Name) {
    if ($TargetVM -notin $Script:FoundVMs) {
        Write-Output "Missed $TargetVM"
        $Script:MissingServers += $TargetVM
    }

}


Write-Output $Compared | Tee-Object -Append -FilePath "$SaveFolder$SlashType$ComparedFileName"

