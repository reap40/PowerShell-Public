#Script to change machines to correct time zone, US states only.
$PickZone = Read-Host "Enter 1 for Eastern Standard Time, 2 for Central Time, 3 for Mountain Time, 4 for Pacific Time, 5 for Alasaka, 6 for Hawaii"
switch -Wildcard ($PickZone) 
  {
    "1" {$TimeZone = "(UTC-05:00) Eastern Time (US & Canada)"}
    "2" {$TimeZone = "(UTC-06:00) Central Time (US & Canada)"}
    "3" {$TimeZone = "(UTC-07:00) Mountain Time (US & Canada)"}
    "4" {$TimeZone = "(UTC-08:00) Pacific Time (US & Canada)"}
    "5" {$TimeZone = "(UTC-09:00) Alaska"}
    "6" {$TimeZone = "(UTC-10:00) Hawaii"}
  }
Get-TimeZone -ListAvailable | Where-Object {$_.DisplayName -eq $TimeZone} | Set-TimeZone -Confirm