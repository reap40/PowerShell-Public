# Installs AD DS and promotes a server to a domain controller
# The script is for domain joined server, run by a domain admin, won't work as currently written on a workgroup server.
# Variables for the script $ComputerName, $SafeModePassword, $LoggedOnUser, $DomainCredentials, $DCName, $DomainName, $SiteName, $ReplicationDC, $ADDSParams, $Job
# The script prompts for the computer name, safe mode password, and domain admin credentials
# Scripts runs on remote DC in the same site as the new DC
# Monitors progress of the job and displays the last 10 lines of the DCPROMO.LOG file
# Author: Patrick Rea
# Date: 2025-02-19
# Version: 1.0
# Disclaimer: This script is provided as-is without any warranty
$ComputerName = Read-Host "Enter name of new DC"
Install-WindowsFeature -ComputerName $ComputerName -Name AD-Domain-Services -IncludeManagementTools

# Prompt for the Safe Mode Administrator Password 
$SafeModePassword = Read-Host -AsSecureString "Enter the Safe Mode Administrator Password"

# Get Credentials of logged domain admin
$LoggedOnUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$DomainCredentials = Get-Credential -Credential $LoggedOnUser

# Get the domain name, replication parter and site name DC will belong to
$DCName = hostname
$DomainName = Get-ADDomain -Server $DCName | Select-Object DNSRoot
$SiteName = Get-ADReplicationSite | Select-Object Name
$ReplicationDC = $DCName + "." + $DomainName.DNSRoot

# Splatted parameters for Install-ADDSDomainController, to increase readability
$ADDSParams = @{
    DomainName                   = $DomainName.DNSRoot
    InstallDns                   = $true
    CreateDnsDelegation          = $false
    DatabasePath                 = "C:\Windows\NTDS"
    LogPath                      = "C:\Windows\NTDS"
    SysvolPath                   = "C:\Windows\SYSVOL"
    SafeModeAdministratorPassword= $SafeModePassword
    NoRebootOnCompletion         = $false
    SiteName                     = $SiteName.Name
    ReplicationSourceDC          = $ReplicationDC
    Credential                   = $DomainCredentials
    Force                        = $true
}

# Install the AD DS Domain Controller using splatting
# The variable $Job can be used to monitor the job status, instead the script uses DCPROMO.LOG to monitor progress
$Job = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    param ($ADDSParams)
    Install-ADDSDomainController @ADDSParams
} -ArgumentList $ADDSParams -AsJob
# Optionally, you can monitor the job status
# Wait-Job -Job $job
# Receive-Job -Job $job
# Continue with other tasks or exit the script

Write-Output "You can monitor the job status using Get-Job and Receive-Job cmdlets."
# The script uses DCPROMO.LOG to monitor progress, when returns to prompt, the remote machine is rebooting
Get-Content \\$ComputerName\C$\Windows\debug\DCPROMO.LOG -Tail 10 -Wait -ErrorAction SilentlyContinue