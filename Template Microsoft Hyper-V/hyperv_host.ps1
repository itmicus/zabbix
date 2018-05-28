
#requires -version 3

<#
.SYNOPSIS
	This script part of the Zabbix 
    Tempalte Microsoft Hyper-V
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
  Creation Date:  25/05/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  hyperv_active.ps1 -ActionType "$1" -Key "$2" -Value "$3"
#>

Param(
    [Parameter(Mandatory = $true)][String]$ActionType,
    [Parameter(Mandatory = $true)][String]$Key,
    [Parameter(Mandatory = $false)][String]$Value
)

$ActionType = $ActionType.ToLower()
$Key = $Key.ToLower()
$Value = $Value.ToLower()


# it is need for correct cyrilic symbols in old OS
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

	
if ($ActionType -eq "discover") {
    # Discover hyper-v virtual switches
    if ($Key -eq "vsw") {	
        $result_json = [pscustomobject]@{
            'data' = @(
                get-wmiobject Win32_PerfRawData_NvspSwitchStats_HyperVVirtualSwitch  | ForEach-Object {
                    $Hyperv_virtualswitch_name = $_.Name;
                    [pscustomobject]@{
                        '{#VIRTUAL_SWITCH_NAME}' = $Hyperv_virtualswitch_name;
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }

    # Discover physical network adapter for hyper-v virtual switches
    if ($Key -eq "vswa") {	
	
        $filter = "NetEnabled='True' and  PhysicalAdapter='True' 
                    AND PNPDeviceID LIKE 'ROOT\\%'"

        $result_json = [pscustomobject]@{
            'data' = @(
                get-wmiobject win32_networkadapter -filter  $filter | ForEach-Object {
                    $VIRTUAL_SWITCH_ADAPTER_NAME = $_.NetConnectionID;
                    $VIRTUAL_SWITCH_ADAPTER_INTERFACEINDEX = $_.InterfaceIndex;
                    Get-WmiObject Win32_PnPEntity -Filter ("PNPDeviceID='$($_.PNPDeviceID)'" -Replace '\\', '\\') | ForEach-Object { 
                        [pscustomobject]@{
                            '{#VIRTUAL_SWITCH_NETWORKADAPTER_NAME}'           = $VIRTUAL_SWITCH_ADAPTER_NAME;
                            '{#VIRTUAL_SWITCH_NETWORKADAPTER_PERF}'           = $_.Name.Replace("/", "_").Replace("#", "_").Replace("(", "[").Replace(")", "]")
                            '{#VIRTUAL_SWITCH_NETWORKADAPTER_INTERFACEINDEX}' = $VIRTUAL_SWITCH_ADAPTER_INTERFACEINDEX
                        }
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }

    # Discover hyper-v not clustered vms
    if ($Key -eq "vms_notclustered") {	
        $result_json = [pscustomobject]@{
            'data' = @(
                get-vm | Where-Object {$_.IsClustered -eq $False} | ForEach-Object {
                    $vm_name = $_.Name;
                    [pscustomobject]@{
                        '{#VM_NOTCLUSTERED_NAME}' = $vm_name;
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }
 
}

if ($ActionType -eq "get") {

    # Get data for physical network adapter by name
    if ($Key -eq "vms_stat") {
        if ($Value -eq "all") {

            $VMs = Get-VM
            $VMsMemoryAssigned = 0
            $VMsMemoryMinimum = 0
            $VMsMemoryMaximum = 0
            $VMsMemoryDemand = 0

            $VMsStateRunning = 0
            $VMsStateOff = 0
            $VMsStateSaved = 0
            $VMsStatePaused = 0
            $VMsStateOther= 0

            foreach ($VM in $VMs) 
            {  
                if ($VM.DynamicMemoryEnabled -eq "True") {
                    $VMsMemoryMinimum += $VM.MemoryMinimum
                    $VMsMemoryMaximum += $VM.MemoryMaximum
                }
                else {
                    $VMsMemoryMinimum += $VM.MemoryStartup
                    $VMsMemoryMaximum += $VM.MemoryStartup
                }
                $VMsMemoryAssigned += $VM.MemoryAssigned
                $VMsMemoryDemand += $VM.MemoryDemand
               
                switch ($VM.State) {
                    "Running" {  $VMsStateRunning += 1}
                    "Saved" {  $VMsStateSaved += 1}
                    "Paused" {  $VMsStatePaused += 1}
                    "Off" {  $VMsStateOff += 1}
                    "Other" {  $VMsStateOther += 1}
                    Default {  $VMsStateOther += 1}
                }
            }

            $result = New-Object PSCustomObject
            $result | Add-Member -type NoteProperty -name VMsMemoryMinimum  -Value $VMsMemoryMinimum
            $result | Add-Member -type NoteProperty -name VMsMemoryMaximum  -Value $VMsMemoryMaximum
            $result | Add-Member -type NoteProperty -name VMsMemoryDemand  -Value $VMsMemoryDemand
            $result | Add-Member -type NoteProperty -name VMsMemoryAssigned  -Value $VMsMemoryAssigned

            $result | Add-Member -type NoteProperty -name VMsStateOff  -Value $VMsStateOff
            $result | Add-Member -type NoteProperty -name VMsStateRunning  -Value $VMsStateRunning
            $result | Add-Member -type NoteProperty -name VMsStateSaved  -Value $VMsStateSaved
            $result | Add-Member -type NoteProperty -name VMsStatePaused  -Value $VMsStatePaused
            $result | Add-Member -type NoteProperty -name VMsStateOther  -Value $VMsStateOther


            $result | ConvertTo-Json
        }
    }
}
	
