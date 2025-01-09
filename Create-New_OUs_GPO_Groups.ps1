#Created on 21 November 2024
#Author Pat Rea
#Is based functional OU setup, with the OU Services already existing.
#This is first version of PowerShell script to create OUs, groups, and a GPO
#Script will assign full control OU permission to AD Group
#Second group will be added so it has local administrator rights on computer objects in the created server OU.
#Will remove GPO permissions from user who created OU and if request remove GPO apply from "Authenticated Users"

#Function to Fix GPO Permissions as required
function FixGPOPermissions ($NewGPOName, $RemoveAuthUsers)
{
  $DC = Get-ADDomainController
  $DC = $DC.HostName
  If ($RemoveAuthUsers -eq "Y")
    {
      Set-GPPermissions -Name $NewGPOName -PermissionLevel None -TargetName "Authenticated Users" -TargetType Group -Server $DC
      Set-GPPermissions -Name $NewGPOName -PermissionLevel GpoRead -TargetName "Authenticated Users" -TargetType Group -Server $DC

    }
  $NewGPO = Get-GPO -Name $NewGPOName -Server $DC | Select-object Name, Owner, ID
  $NewGPO.Owner
  $GPOQuery = "{" + $NewGPO.id.Guid + "}"
  $NewGPOobject = Get-ADObject -filter  "'Name -like '$GPOQuery'" -Server $DC # $NewGPO.id.Guid
  $Ownr = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Domain Admins").SID
  $ACLGPO = Get-ACL -Path "ad:$($NewGPOobject.DistinguishedName)"
  $ACLGPO.SetOwner($Ownr)
  Set-ACL -ACLObject $ACLGPO -Path "ad:$($NewGPOobject.DistinguishedName)" 
  (Get-ACL -Path "ad:$($NewGPOobject.DistinguishedName)").Owner  
}

#Function to Get Intials, used in comment section of GPO
#Works even if no middle name, middle initials
function GetInitials ($CurrentUser)
{
   $DomainNetBiosName = (Get-ADDomain).NetBiosName
   $CurrentUser = $CurrentUser.Replace("$DomainNetBiosName`\", '')
   $User = Get-ADUser -Identity $CurrentUser -Properties Initials
   $UserInitials = $User.GivenName.Substring(0,1) + $User.Initials + $User.Surname.Substring(0,1)
   Return $UserInitials
}
 
#Parameters and Variables
$Date = Get-Date -Format dd-MMM-yyyy
$DomainName = (Get-ADDomain).DistinguishedName
$StartingOU = "OU=Services,$DomainName"
$DC = Get-ADDomainController
$DC = $DC.HostName
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$GPONameStart = Read-Host "Enter default GPO name beginning, i.e MyORG"
$Initials = GetInitials ($CurrentUser) 
$ChangeRequestNumber = Read-Host "Enter Change request number"
$Comment = "Created on $Date, $ChangeRequestNumber - $Initials"
$Service =  Read-Host "Parent OU Name, i.e. SQL "
#Either enter a single SubOU Site name using Read-Host or comment out Read-Host and
#Enter a list of Parent OU name, Example below
#$SubOUSiteNames = "Tampa","Atlanta"
$SubOUSiteNames = Read-Host "Enter site name, i.e. Tampa "
Try {Get-ADOrganizationalUnit "OU=$Service,$StartingOU"}
Catch
  { Write-Host "OU $Service doesn't exist"
    New-ADOrganizationalUnit -Name $Service -Path $StartingOU -ProtectedFromAccidentalDeletion:$true -server $DC -Confirm 
  }

#Main Loop
ForEach ($SubOUSiteName in $SubOUSiteNames)
{
   $ServiceOU = "OU=$Service," + $StartingOU
   $SubOUSiteNameOU = "OU=$SubOUSiteName," + $ServiceOU
   $OUtoLinkGPO = "OU=Servers,$SubOUSiteNameOU"
   
   New-ADOrganizationalUnit -Name $SubOUSiteName -Path $ServiceOU -ProtectedFromAccidentalDeletion:$true -server $DC -Confirm
   New-ADOrganizationalUnit -Name "Groups" -Path $SubOUSiteNameOU -ProtectedFromAccidentalDeletion:$true -server $DC -Confirm
   New-ADOrganizationalUnit -Name "Servers" -Path $SubOUSiteNameOU -ProtectedFromAccidentalDeletion:$true -server $DC -Confirm
   New-ADOrganizationalUnit -Name "ServiceAccounts" -Path $SubOUSiteNameOU -ProtectedFromAccidentalDeletion:$true -server $DC -Confirm
   New-ADGroup -Name "$($SubOUSiteName)_$($Service)_ADMGMT" -GroupScope Global -GroupCategory Security -Path "OU=Groups,$SubOUSiteNameOU" -Description "Management Group for [$SubOUSiteName] [$Service]" -Server $DC -Confirm
   New-ADGroup -Name "la_$($SubOUSiteName)_$($Service)_admin" -GroupScope Global -GroupCategory Security -Path "OU=Groups,$SubOUSiteNameOU" -Description "Local Admin Group for [$SubOUSiteName] [$Service]" -Server $DC -Confirm
   
   $NewGPOName = $GPONameStart + "_" + $Service + "_" + $SubOUSiteName + "_Customizations"
   New-GPO -Name $NewGPOName -Server $DC -Comment $Comment -Confirm  | New-GPLink -Target $OUtoLinkGPO -Confirm
   $RemoveAuthUsers = Read-Host "Enter Y to remove 'GPO apply' from Authenticated Users for GPO $NewGPOName" 
   Set-GPPermissions -Name $NewGPOName -PermissionLevel None -TargetName $CurrentUser -TargetType User -Server $DC -Confirm
   FixGPOPermissions $NewGPOName $RemoveAuthUsers   
   
   $lapsPasswordGuid = New-Object system.guid "d04b1f17-b80b-454f-9231-031050ea0a0d"
   $lapsPasswordExpirationTimeGuid = New-Object system.guid "7f15a2c7-95ac-4a4e-b12f-56608e4b51d4"
   $computerGuid = New-Object system.guid "bf967a86-0de6-11d0-a285-00aa003049e2"
   $groupGuid =  New-Object system.guid "bf967a9c-0de6-11d0-a285-00aa003049e2"
   $allGuid = New-Object system.guid "00000000-0000-0000-0000-000000000000"
   $userGuid = New-Object system.guid "bf967aba-0de6-11d0-a285-00aa003049e2"
   $ADMGMT = Get-ADGroup "$($SubOUSiteName)_$($Service)_ADMGMT" -Server $DC
   $sid = New-Object System.Security.Principal.SecurityIdentifier $ADMGMT.SID
   $objectPath = "AD:\OU=Servers,$SubOUSiteNameOU"
   $objectpathgroup = "AD:\OU=Groups,$SubOUSiteNameOU"
   $objectpathserviceaccount = "AD:\OU=ServiceAccounts,$SubOUSiteNameOU"
   
   $aclsServer = Get-ACL $objectPath -ErrorAction Stop 
   $readlapsPasswordACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"ReadProperty, ExtendedRight","Allow",$lapsPasswordGuid,"All",$computerGuid
   $readlapsPasswordExpirationTimeACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"ReadProperty","Allow",$lapsPasswordExpirationTimeGuid,"Descendents",$computerGuid
   $genericallserver = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"GenericAll","Allow",$allGuid,"Descendents",$computerGuid
   $createdeleteserver = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild, DeleteChild","Allow",$computerGuid,"All",$allGuid
   $aclsServer.AddAccessRule($readlapsPasswordACE)
   $aclsServer.AddAccessRule($readlapsPasswordExpirationTimeACE)
   $aclsServer.AddAccessRule($createdeleteserver)
   $aclsServer.AddAccessRule($genericallserver)
   Set-Acl -AclObject $aclsServer $objectPath -ErrorAction Stop
   
   $aclsGroup = Get-ACL $objectpathgroup -ErrorAction Stop
   $genericallgroup = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"GenericAll","Allow",$allGuid,"Descendents",$groupGuid
   $createdeletegroup = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild, DeleteChild","Allow",$groupGuid,"All",$allGuid
   $aclsGroup.AddAccessRule($createdeletegroup)
   $aclsGroup.AddAccessRule($genericallgroup)
   Set-Acl -AclObject $aclsGroup $objectpathgroup -ErrorAction Stop
      
   $aclsServiceAccount = Get-ACL $objectpathserviceaccount -ErrorAction Stop
   $genericallServiceAccount = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"GenericAll","Allow",$allGuid,"Descendents",$userGuid
   $createdeleteServiceAccount = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild, DeleteChild","Allow",$userGuid,"All",$allGuid
   $aclsServiceAccount.AddAccessRule($createdeleteServiceAccount)
   $aclsServiceAccount.AddAccessRule($genericallServiceAccount)
   Set-Acl -AclObject $aclsServiceAccount $objectpathserviceaccount -ErrorAction Stop
   Set-ADGroup -Identity $ADMGMT -Description "ACLComputerALL;ACLGroupAll;ACLServiceAccountall;ACLReadLAPS $($objectpath.split(",")[0])"  
}