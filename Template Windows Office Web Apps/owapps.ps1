
#requires -version 3

<#
.SYNOPSIS
	This script part of the Zabbix 
    Tempalte Microsoft Office Web Apps
    Requrired PowerShell 3.0 or higher
.DESCRIPTION
  This sricpt using for LLD and trapper
.PARAMETER <ActionType>
	Type of action: dsicover, get or other
.PARAMETER <Key>
	Key - attirbute for 	
.PARAMETER <Value>
	Value - var for key, may be single or multiply
.INPUTS
  Input 3 variables

.OUTPUTS
  Output in JSON format for Zabbix 
.NOTES
  Version:        1.0
  Author:         p.kuznetsov@itmicus.ru
  Creation Date:  02/07/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
    owapps.ps1 -ActionType "$1" -Key "$2" -Value "$3"
#>



Param(
    [Parameter(Mandatory = $true)][String]$ActionType,
    [Parameter(Mandatory = $true)][String]$Key,
    [Parameter(Mandatory = $false)][String]$Value
)

$DISCOVER_ONLY_NOT_EXPIRED_CERTIFICATES = $True


$ActionType = $ActionType.ToLower()
$Key = $Key.ToLower()
$Value = $Value.ToLower()

# it is need for correct cyrilic symbols in old OS
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function GetHTTPStatus([string]$url) {
    # First we create the request.
    $HTTP_Request = [System.Net.WebRequest]::Create($url)

    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()

    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    $HTTP_Response.Close()
    return $HTTP_Status 
}


if ($ActionType -eq "discover") {
   
}

if ($ActionType -eq "get") {
    if ($Key -eq "farm_status") {
        
        $farm = Get-OfficeWebAppsFarm -WarningAction silentlyContinue

        $result = New-Object PSCustomObject
            
        if ($farm.Machines -ne $null) {
            $current_machine_name = (Get-OfficeWebAppsMachine).MachineName
            $current_machine_is_health = (Get-OfficeWebAppsMachine).HealthStatus
            if ($current_machine_is_health -eq "Unhealthy") {
                $current_machine_is_health = 0
            }
            else {
                $current_machine_is_health = 1
            }	
            $result | Add-Member -type NoteProperty -name MachineHealth -Value $current_machine_is_health
        }
        else {
            $result | Add-Member -type NoteProperty -name MachineHealth -Value 1
        }
            
            
        $farm_cert_name = $farm.CertificateName
        $cert = Get-ChildItem -Path cert:\ | Where-Object { $_.FriendlyName -eq $farm_cert_name } 
        $days_to_expr = ($cert.NotAfter - [DateTime]::Now).Days
            
        $url_internal = $farm.InternalURL.AbsoluteUri + "/hosting/discovery"
        $url_external = $farm.ExternalURL.AbsoluteUri + "/hosting/discovery"
            
        $internal_url_status = GetHTTPStatus -url $url_internal
        $external_url_status = GetHTTPStatus -url $url_external 
            
        $result | Add-Member -type NoteProperty -name CertificatDayToExpired -Value $days_to_expr 
        $result | Add-Member -type NoteProperty -name InternalURLStatus -Value $internal_url_status
        $result | Add-Member -type NoteProperty -name ExternalURLStatus -Value $external_url_status
            
        $result | ConvertTo-Json
    }   
}
	
