#Written by Patrick Rea, 17 Jan 2025
#Uses CSV file created by PowerShell script Subnets_no_matching_reverse_zone_export.ps1
#Checks Reverse DNS doesn't exist and creates if doesn't exist.
$DocumentsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents"
$ReverseDNSZonetoCreate = Import-Csv $DocumentsPath\Subnets_no_matching_reverse_zone.csv
$DC = Get-ADDomainController
$DC = $DC.HostName
ForEach ($Zone in $ReverseDNSZonetoCreate)
  {
    $DNSZone = Get-DnsServerZone -Name $ReverseZone -ComputerName $DC -ErrorAction SilentlyContinue
    If ($DNSZone) 
      {
        Write-Output "Zone found: $($DNSZone.ZoneName)"
      } 
    Else 
     {
         Write-Output "Zone '$ReverseZone' does not exist. Creating Zone"         
         Add-DnsServerPrimaryZone -NetworkID $Subnet.Name -ReplicationScope Domain -ComputerName $DC -Confirm
      }
  }