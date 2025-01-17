#Written by Patrick Rea, 17 Jan 2025
#Finds all /24 subnets in Active Directory Sites and Services and checks if matching reverse zone exist.
#Reverse zones and subnets are exported to a CSV file
#This CSV file can be used later to create the reverse zone, allowing for an approval process to occur.
Function Convert-IPToReverseDNS {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )

    # Split and reverse the IP address into octets
    $reversedOctets = ($IPAddress -split '\.')[2..0]

    # Construct the reverse DNS format
    $reverseDNS = ($reversedOctets -join '.') + ".in-addr.arpa"

    # Output the result
    return $reverseDNS
}

$DC = Get-ADDomainController
$DC = $DC.HostName
$Subnets = Get-ADReplicationSubnet -Filter * -Server $DC | Where {$_.Name -like "*/24"} | Select Name
ForEach ($Subnet in $Subnets)
  {
    $SubnetName = $Subnet.Name -Replace('/.*','')
    $ReverseZone = Convert-IPToReverseDNS $SubnetName
    $DNSZone = Get-DnsServerZone -Name $ReverseZone -ComputerName $DC -ErrorAction SilentlyContinue
    $SubnetExport = [PSCustomObject]@{
    Subnet = $Subnet.Name
    ReverseZone = $ReverseZone
    }
    $DocumentsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents"
    If ($DNSZone) 
      {
        Write-Output "Zone found: $($DNSZone.ZoneName)"
      } 
    Else 
     {
         Write-Output "Zone '$ReverseZone' does not exist. Creating Zone"
         $SubnetExport | Export-Csv -NoTypeInformation -Append $DocumentsPath\Subnets_no_matching_reverse_zone.csv         
     }

 }