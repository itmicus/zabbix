
#requires -version 3

<#
.SYNOPSIS
	This script part of the Zabbix 
    Tempalte Microsoft Windows Certificates
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
  Creation Date:  27/06/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  hyperv_active.ps1 -ActionType "$1" -Key "$2" -Value "$3"
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

	
if ($ActionType -eq "discover") {
    # Discover certificates in \local machine\Personal\
    if ($Key -eq "lm_certs") {	
        # filter by Subject
        $result_json = [pscustomobject]@{
            'data' = @(
                Get-ChildItem -Path Cert:\LocalMachine\My\  | ForEach-Object {
                    # get only valid certificates
                    if ($DISCOVER_ONLY_NOT_EXPIRED_CERTIFICATES) {
                        # if expired get next certificate
                        if ((New-TimeSpan -End $_.NotAfter).Days -lt 0) {
                            return  # yes yes yes, return not continue! =)
                        }
                    }
                   
                    $CN = $_.Subject.Split(",")[0].Split("=")[1]
                    [pscustomobject]@{
                        '{#LM_CERT_SUBJECT}'      = $_.Subject;
                        '{#LM_CERT_CN}'           = $CN ;
                        '{#LM_CERT_FRIENDLYNAME}' = $_.FriendlyName  ;
                        '{#LM_CERT_THUMBPRINT}'   = $_.Thumbprint;
                        '{#LM_CERT_SERIALNUMBER}' = $_.SerialNumber;
                    }
                }
            )
        }	| ConvertTo-Json    
        [Console]::WriteLine($result_json)
    }
}

if ($ActionType -eq "get") {
    # 
    if ($Key -eq "lm_cert") {
        # value is Thumbprint
        if ($Value -ne $null) {

            $cert = Get-ChildItem -Path Cert:\LocalMachine\My\ | Where-Object {$_.Thumbprint -eq $Value}
            $daystoexpire = (New-TimeSpan -End $cert.NotAfter).Days
            # need get cert status

            $result = New-Object PSCustomObject
            $result | Add-Member -type NoteProperty -name DaysToExpire  -Value $daystoexpire
            $result | Add-Member -type NoteProperty -name IssuedBy  -Value $cert.IssuerName.Name
            $result | Add-Member -type NoteProperty -name IssuedDate  -Value $cert.NotBefore.ToString("dd.MM.yyyy hh:mm:ss")
            $result | Add-Member -type NoteProperty -name ExpireDate  -Value $cert.NotAfter.ToString("dd.MM.yyyy hh:mm:ss")
            $result | Add-Member -type NoteProperty -name Thumbprint  -Value $cert.Thumbprint
            #$result | Add-Member -type NoteProperty -name status  -Value

            $result | ConvertTo-Json
        }
    }   
}
	
