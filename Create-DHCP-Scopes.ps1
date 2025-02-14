# Description: This script creates DHCP scopes based on a CSV file stored in the user's Documents folder
# Because the parameters ComputerName is used it does not need to be run on the DHCP server
# Checks if the scope already exists before creating it
# After creating the scope, it sets the gateway option value, and adds an exclusion range for the gateway
# I splatted the parameters for Add-DhcpServerv4Scope to make the script more readable
# Because the parameters are splatted, ensure the CSV file has values for Name, StartRange, EndRange, SubnetMask, Description, and ComputerName
# Null values are not allowed for these parameters
# Author: Patrick Rea
# Date: 2025-02-01
# Version: 1.1
$DocumentsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents"
$Scopes = Import-Csv $DocumentsPath\Scopes.csv
Foreach ($Scope in $Scopes)
  {
    $ScopeExist = Get-DhcpServerv4Scope -Name $Scope.Name -ErrorAction SilentlyContinue
    If ($null -eq $ScopeExist)
      {
        $ScopeParams = @{
            Name        = $Scope.Name
            StartRange  = $Scope.StartRange
            EndRange    = $Scope.EndRange
            SubnetMask  = $Scope.SubnetMask
            State       = 'Active'
            Description = $Scope.Description
            ComputerName= $Scope.ComputerName
        }
        Add-DhcpServerv4Scope @ScopeParams
        Set-DhcpServerv4OptionValue -ScopeId $Scope.Name -OptionId 3 -Value $Scope.Gateway
        Add-DhcpServerv4ExclusionRange -ScopeId $Scope.Name -StartRange $Scope.Gateway -EndRange $Scope.Gateway
      }
    Else
      {
        Write-Host "Scope $($Scope.Name) already exists"
      }
  }