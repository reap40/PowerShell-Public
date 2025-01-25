# Function to split a CIDR block into /24 subnets
# Any subnets with CIDR greater than or equal 24 will return single /24 subnet
# Written by Patrick Rea, completed 21 Jan 2025, the else statement was written with an AI assist.
# Exports all subnets to a CSV file saved to my documents, allowing for review and usage by other PowerShell scripts.
# Script calling function is Subnets_no_matching_reverse_zones_export
Function Get-SubnetsFromCIDR 
 {
    param 
       (
        [string]$CIDR
       )

    # Define the CSV file path
    $DocumentsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents"
    $CsvFile = Join-Path -Path $DocumentsPath -ChildPath "CIDR24_Subnets.csv"

    # Split the CIDR into base IP and subnet mask
    $Subnets = ""
    $BaseIP, $Prefix = $CIDR -split "/"
    $Prefix = [int]$Prefix

    If ($Prefix -ge 24) 
      {
        $Subnets = [PSCustomObject]@{
        Name = "$BaseIP/24"
          }
          $Subnets | Export-Csv $CsvFile -NoTypeInformation -Append
        
      }
    Else
     {
      # Convert the base IP into a 32-bit integer
      $ipBytes = [System.Net.IPAddress]::Parse($BaseIP).GetAddressBytes()
      [array]::Reverse($ipBytes)  # Reverse byte order for calculations
      $BaseIPInt = [BitConverter]::ToUInt32($ipBytes, 0)
      
      # Calculate the subnet mask
      $SubnetMask = -bnot ([math]::Pow(2, 32 - $Prefix) - 1)
      
      # Calculate the start and end IPs
      $NetworkStart = $BaseIPInt -band $SubnetMask
      
      # Calculate the number of /24 subnets
      $NumSubnets = [math]::Pow(2, 24 - $Prefix)
      
      Write-Output "Splitting $CIDR into $NumSubnets /24 subnets:"
      
      # Generate /24 subnets
      For ($i = 0; $i -lt $NumSubnets; $i++) 
       {
          # Calculate the start IP of each /24 subnet
          $SubnetStart = $NetworkStart + ($i -shl 8)
      
          # Convert integer back to IP
          $ipBytes = [BitConverter]::GetBytes($SubnetStart)
          [array]::Reverse($ipBytes)
          $SubnetIP = [System.Net.IPAddress]::new($ipBytes).ToString()
          $Subnets = [PSCustomObject]@{
             Name = "$SubnetIP/24"
          }
          $Subnets | Export-Csv $CsvFile -NoTypeInformation -Append
        }
      }
     Return $Subnets 
   }