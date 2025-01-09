#Script to export guids to my documents folder used to set security on objects, for example see script Create-New_OUs-GPO-Groups.ps1
#Active Directory module is required
Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext -LDAPFilter "(schemaidguid=*)" -Properties LdapDisplayName,SchemaIdGuid | ForEach-Object {

    $SchemaGuid = [pscustomobject]@{

        Name = $_.LdapDisplayName
        SchemaIdGuid = [GUID]$_.SchemaIdGuid

    }

    [array]$TotalGuids += $SchemaGuid

} 
$MyDocuments ="$env:USERPROFILE\Documents"
$TotalGuids | Export-Csv $MyDocuments\guids.csv -NoTypeInformation