
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


if ([System.Diagnostics.EventLog]::SourceExists("Zabbix script") -eq $False) {
    New-EventLog -LogName "Application" -Source "Zabbix script"
}
$SCRIPT_DESCRIPTION = 'Tempalte Microsoft Office Web Apps';
$SCRIPT_NAME = 'owapps.ps1';
$sessionId = (Get-Process -PID $pid).SessionID
$ScriptName = $MyInvocation.MyCommand.Name
$PowershellVerText = ($PSVersionTable.PSVersion.major).ToString() + "." + ($PSVersionTable.PSVersion.minor).ToString()
$whoami = whoami
$Random = Get-Random
$StartTime = Get-Date
$start_event_message = "Start script=$SCRIPT_NAME;$SCRIPT_DESCRIPTION with arguments ActionType=$ActionType, Key=$Key, Value=$Value, current_user=$whoami, PowerShell=$PowershellVerText, PowerShellSessionId=$sessionId, RunId=$Random"
Write-EventLog -LogName Application -Source "Zabbix script" -EntryType Information -EventId 100 -Message "$start_event_message"
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
    if ($Key -eq "officewebfarm") {	
        # filter by Subject
        $farm = Get-OfficeWebAppsFarm -WarningAction silentlyContinue
        $result = New-Object PSCustomObject
        $result | Add-Member -type NoteProperty -name InternalURL -Value $internal_url_status
        $result | Add-Member -type NoteProperty -name ExternalURL -Value $external_url_status
            
       
        $result_json = [pscustomobject]@{
            'data' = @(
                $result 
            )
        }	| ConvertTo-Json    
        [Console]::WriteLine($result_json)
    }
}

if ($ActionType -eq "get") {

    if ($Key -eq "machine_status") {
        
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
    
        $url_internal = $farm.InternalURL.AbsoluteUri + "/hosting/discovery"
        $url_external = $farm.ExternalURL.AbsoluteUri + "/hosting/discovery"

        $internal_url_status = GetHTTPStatus -url $url_internal
        if ($internal_url_status -eq 200) {
            $internal_url_status = 1
        }
        else {
            $internal_url_status = 0
        }
        
        $external_url_status = GetHTTPStatus -url $url_external
        if ($external_url_status -eq 200) {
            $external_url_status = 1
        }
        else {
            $external_url_status = 0
        }
            
        $result | Add-Member -type NoteProperty -name InternalURLStatus -Value $internal_url_status
        $result | Add-Member -type NoteProperty -name ExternalURLStatus -Value $external_url_status
        $result | Add-Member -type NoteProperty -name MachineName -Value $current_machine_name

        Write-EventLog -LogName Application -Source "Zabbix script" -EntryType Information -EventId 200 -Message "$result"

        $result | ConvertTo-Json
    }   

    if ($Key -eq "farm_status") {
        
        $farm = Get-OfficeWebAppsFarm -WarningAction silentlyContinue

        $result = New-Object PSCustomObject
            
        $inc = Get-Content "C:\ProgramData\Microsoft\OfficeWebApps\Data\local\OfficeVersion.inc" | ConvertFrom-StringData
        $version = "{0}.{1}.{2}.{3}" -f $inc.RMJ, $inc.RMM, $inc.RUP, $inc.RPR
        
        $farm_cert_name = $farm.CertificateName
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My\ | Where-Object { $_.FriendlyName -eq $farm_cert_name } 
        $days_to_expr = (New-TimeSpan -End $cert.NotAfter).Days 
            
        $result | Add-Member -type NoteProperty -name CertificatDayToExpired -Value $days_to_expr 
        $result | Add-Member -type NoteProperty -name Version -Value $version
  
        Write-EventLog -LogName Application -Source "Zabbix script" -EntryType Information -EventId 200 -Message "$result"

        $result | ConvertTo-Json
    }   

}
