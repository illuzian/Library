# Takes a CSV file of IPs and applies a block to all WAF policies in the tenant
param(
    
    [Parameter(Mandatory=$true)][string]$CSVFile,
    [Parameter(Mandatory=$true)][string]$RuleName,
    [Parameter()][bool]$WhatIf = $true
)

# Check WhatIf and tell user if enabled.
if ($WhatIf) {
    Write-Output "WhatIf has been set to yes, no changes will be made. Please provide '-Whatif `$false`' to commit changes"
}

# Check for Az module
if ('Az' -notin (Get-InstalledModule).Name) {
    Write-Output "Please install with 'Install-Module -Scope CurrentUser Az'"
    return 1
}

$ExistingWhatIfPreference = $WhatIfPreference

$IPListCSV = Import-Csv -Path $CSVFile

# Validate input CSV
if ('IP' -in ($IPListCSV | Get-Member -MemberType NoteProperty).Name) {
    $IOCIPs = $IPListCSV.IP
} else {
    Write-Output "CSVFile file must be a path to a single column CSV file with IP as the header."
    return 4
}
# Validate rulename
if ($RuleName -notmatch '^[a-zA-Z][a-zA-Z0-9]*$') {
    Write-Output "RuleName must start with a letter and can only container letters and numbers."
    return 3
}




$Subs = Get-AzSubscription 

ForEach ($Sub in $Subs) {
  $Sub | Set-AzContext

  $AppGWFirewallPolicies = Get-AzApplicationGatewayFirewallPolicy
  # Find first free policy priority
  ForEach ($FWPolicy in $AppGWFirewallPolicies) {
      $UsedPriorities = @()
      ForEach ($Rule in $FWPolicy.CustomRules) {
          $UsedPriorities += $Rule.Priority
      }
      ForEach ($CompareNumber in 1..100) {
          if ($CompareNumber -notin  $UsedPriorities) {
              $FreePriority = $CompareNumber
              break
          }
      }


    # Set the match variable to RemoteAddr to match against client IPs 
    $FWMatchVariable = New-AzApplicationGatewayFirewallMatchVariable -VariableName RemoteAddr
    # Match against the import IOC
    $FWMatchCondition = New-AzApplicationGatewayFirewallCondition -MatchVariable $FWMatchVariable -Operator IPMatch -MatchValue $IOCIPs -NegationCondition $False
    $FWRule = New-AzApplicationGatewayFirewallCustomRule -Name $RuleName -Priority $FreePriority -RuleType MatchRule -MatchCondition $FWMatchCondition -Action Block
    $FWPolicy.CustomRules.Add($FWRule)

    $WhatIfPreference = $WhatIf
    Set-AzApplicationGatewayFirewallPolicy -InputObject $FWPolicy
    $WhatIfPreference = $ExistingWhatIfPreference
    
  }
    #   if (($FWPolicy.CustomRules).Name -contains $RuleName) {
    #       $FWPolicyRule = $FWPolicy.CustomRules | Where-Object -Property Name -eq PolicyName

    #       $FWPolicy.CustomRules.Remove($FWPolicyRule)

          
    #   }
  

}
