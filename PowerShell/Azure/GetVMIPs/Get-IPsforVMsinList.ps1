# Finds the IP addresses of VMs in a VM list csv with column name "Name"
param (
    $VMListFile = '/path/to/vm_list',
    $VerboseOut = $true,
    $TenantId = ''
)

$output = if ($VerboseOut) { 'Out-Default' } else { 'Out-Null' }

$VMList = import-csv -path $VMListFile 

$Subs = Get-AzSubscription 
$ScriptTS = Get-Date -Format 'yyyyMMddHHmm'




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

                $TGTSavePath = $SavePath
                $TGTVM = $VM
                $TGTSub = $Sub

                $TGTTenant = $TenantId


                $TGTVM.id -match '\/subscriptions\/([^\/]*)\/resourceGroups\/([^\/]*)\/'
                $sub = $matches[1]
                $rg = $matches[2]

                Set-AzContext -SubscriptionId "$sub" -TenantId "$TGTTenant"
                # Get-AzResourceGroup -ResourceGroupName "$rg"



                $NetworkProfile = $TGTVM.NetworkProfile.NetworkInterfaces.id.Split("/")|Select -Last 1
                $IPConfig = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PrivateIpAddress
                $IPData = [PSCustomObject]@{
                    host = $VM.Name
                    ip = $IPConfig
                }
                $IPData | Export-Csv -Append -Path ./HostMapIP.csv



            
            
        }
    }


    

Write-Output 'Jobs saved in $ScanJobs'
$ScanJobs
$ComparedFileName = 'missing.out'
$Script:MissingServers = @()
ForEach ($TargetVM in $VMList.Name) {
    if ($TargetVM -notin $Script:FoundVMs) {
        Write-Output "Missed $TargetVM"
        $Script:MissingServers += $TargetVM
    }

}


Write-Output $Compared | Tee-Object -Append -FilePath "$SaveFolder$SlashType$ComparedFileName"

