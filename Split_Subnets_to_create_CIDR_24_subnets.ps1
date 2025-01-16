# Function to split a CIDR block into /24 subnets
function Get-SubnetsFromCIDR {
    param (
        [string]$CIDR
    )

    # Split the CIDR into base IP and subnet mask
    $baseIP, $prefix = $CIDR -split "/"
    $prefix = [int]$prefix

    if ($prefix -ge 24) {
        Write-Error "The CIDR block prefix must be less than 24 to split into /24 subnets."
        return
    }

    # Convert the base IP into a 32-bit integer
    $ipBytes = [System.Net.IPAddress]::Parse($baseIP).GetAddressBytes()
    [array]::Reverse($ipBytes)  # Reverse byte order for calculations
    $baseIPInt = [BitConverter]::ToUInt32($ipBytes, 0)

    # Calculate the subnet mask
    #$subnetMask = -shl 32 - $prefix
    $subnetMask = -bnot ([math]::Pow(2, 32 - $prefix) - 1)

    # Calculate the start and end IPs
    $networkStart = $baseIPInt -band $subnetMask
    
    # Calculate the number of /24 subnets
    $numSubnets = [math]::Pow(2, 24 - $prefix)

    Write-Output "Splitting $CIDR into $numSubnets /24 subnets:"

    # Generate /24 subnets
    for ($i = 0; $i -lt $numSubnets; $i++) {
        # Calculate the start IP of each /24 subnet
        $subnetStart = $networkStart + ($i -shl 8)

        # Convert integer back to IP
        $ipBytes = [BitConverter]::GetBytes($subnetStart)
        [array]::Reverse($ipBytes)
        $subnetIP = [System.Net.IPAddress]::new($ipBytes).ToString()

        Write-Output "$subnetIP/24"
    }
}

# Example: Split 192.168.0.0/22 into /24 subnets
$CIDR = "192.168.25.0/23"
Get-SubnetsFromCIDR -CIDR $CIDR