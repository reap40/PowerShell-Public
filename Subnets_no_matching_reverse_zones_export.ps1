# Written by Patrick Rea, 17 Jan 2025
# Finds all /24 subnets in Active Directory Sites and Services and checks if matching reverse zone exist.
# Calls function Get-SubnetsFromCIDR.ps1, function is in a separate file, 
# Reverse zones and subnets are exported to a CSV file
# This CSV file can be used later to create the reverse zone, allowing for an approval process to occur.
# The CSV file is used by script Create_reverse_zone_from_imported_csv.ps1
# You may need to update the variables $DocumentsPath and $FunctionPath

Function Convert-IPToReverseDNS {
  param (
      [Parameter(Mandatory = $true)]
      [string]$IPAddress
  )

  # Split and reverse the IP address into octets
  $ReversedOctets = ($IPAddress -split '\.')[2..0]

  # Construct the reverse DNS format
  $ReverseDNS = ($ReversedOctets -join '.') + ".in-addr.arpa"

  # Output the result
  return $ReverseDNS
}

$DocumentsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents"
$FunctionPath = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop"
. $FunctionPath\Get-SubnetsFromCIDR.ps1
$DC = Get-ADDomainController
$DC = $DC.HostName
$Subnets = Get-ADReplicationSubnet -Filter * -Server $DC | Select-Object Name
ForEach ($Subnet in $Subnets)
{
  Get-SubnetsFromCIDR $Subnet.Name 
}
$All24Subnets = Import-Csv $DocumentsPath\CIDR24_Subnets.csv
ForEach ($All24Subnet in $All24Subnets)
{
  $SubnetName = $All24Subnet.Name -Replace('/.*','')
  $ReverseZone = Convert-IPToReverseDNS $SubnetName
  $DNSZone = Get-DnsServerZone -Name $ReverseZone -ComputerName $DC -ErrorAction SilentlyContinue
  $SubnetExport = [PSCustomObject]@{
  Subnet = $All24Subnet.Name
  ReverseZone = $ReverseZone
  }
  If ($DNSZone) 
    {
      Write-Output "Zone found: $($DNSZone.ZoneName)"
    } 
  Else 
   {
       Write-Output "Zone '$ReverseZone' does not exist. Creating Zone"
       $SubnetExport | Export-Csv -NoTypeInformation -Append $DocumentsPath\Subnets_no_matching_reverse_zone.csv
       #Add-DnsServerPrimaryZone -NetworkID $Subnet.Name -ReplicationScope Domain -ComputerName $DC -Confirm
   }

}