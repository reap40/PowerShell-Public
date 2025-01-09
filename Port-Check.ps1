# May 01, 2018
# Check the availability of Ports for a Domain Controllers, or 
# SQL Server or MECM Server or (Distributed File System)DFS Server 
# This does not consider IPSEC, UDP Ports, nor Ephemeral Ports. 

# Reset response status to prevent false positive
$Result = 0

# Prompt for DC Name and test name
$Server = Read-Host -Prompt "Please provide server name"
$TestName = Read-Host "Enter Test Name, either AD, SQL, MECM, DFS"
$TestName = $TestName.ToUpper()
switch ($TestName)
{
    'AD' {
           # Designated TCP Ports for AD (DNS,Kerb,RPC,LDAP,SMB,Kerb\Auth,LDAPS,GC,GCS,ADWS)
           $Ports ="53","88","135","139","389","445","464","636","3268","3269","9389"
         }
    'DFS' {
            # Designated TCP Ports for DFS (RPC,NetBIOS,LDAP,SMB,DFSR)
            $Ports ="135","139","389","445","5722"
           }
    'SQL' {
            # Designated TCP Ports for SQL (SSMS\Trans,SQL,SQLDAC,Broker) Add 80 and 443 below for Reporting Services.
            $Ports = "135","1433","1434","4022"
          }
    'MECM'{
            # Designated TCP Ports for MECM (HTTP,RPC,NetBIOS,HTTPs,SMB,WSUS,Client Notify)
            $Ports = "80","135","139","443","445","8530","10123"
          }
              
}
If (!($Ports))
     {
       Write-Host "Bad Test Name" 
     }
Else
    {
      Write-Host "`n----------------------------------------------------------------------------`n"
      Write-Host "Testing $TestName Ports - $Ports :`n" -ForegroundColor Cyan
    }
ForEach ($P in $Ports)
   {
    $Result = (Test-NetConnection -Port $p -computername $Server).TcpTestSucceeded
    If($Result -match "false")
       {
        Write-Host "Failure: Port  $P" -Fore Red
       }
    Else
       {
        Write-Host "Success: Port  $P" -Fore Green
       }
   }