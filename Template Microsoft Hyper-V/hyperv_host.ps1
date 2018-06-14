
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
    if ($Key -eq "va") {	
	
        $filter = "NetEnabled='True' and  PhysicalAdapter='True' 
                    AND PNPDeviceID LIKE 'ROOT\\%'"

        $result_json = [pscustomobject]@{
            'data' = @(
                get-wmiobject win32_networkadapter -filter  $filter | ForEach-Object {
                    $HYPERV_ADAPTER_NAME = $_.NetConnectionID;
                    $HYPERV_ADAPTER_INTERFACEINDEX = $_.InterfaceIndex;
                    Get-WmiObject Win32_PnPEntity -Filter ("PNPDeviceID='$($_.PNPDeviceID)'" -Replace '\\', '\\') | ForEach-Object { 
                        [pscustomobject]@{
                            '{#HYPERV_NETWORKADAPTER_NAME}'           = $HYPERV_ADAPTER_NAME;
                            '{#HYPERV_NETWORKADAPTER_PERF}'           = $_.Name.Replace("/", "_").Replace("#", "_").Replace("(", "[").Replace(")", "]")
                            '{#HYPERV_NETWORKADAPTER_INTERFACEINDEX}' = $HYPERV_ADAPTER_INTERFACEINDEX
                        }
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }

    # Discover hyper-v not clustered vms
    if ($Key -eq "vm") {	
        $result_json = [pscustomobject]@{
            'data' = @(
                get-vm | Where-Object {$_.IsClustered -eq $False} | ForEach-Object {
                    $vm_name = $_.Name;
                    [pscustomobject]@{
                        '{#VM_NAME}' = $vm_name;
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }
 
    # Discover in not clustered virtual machine's network adapters
    if ($Key -eq "vm_na") {
        $vms = get-vm | Where-Object {$_.IsClustered -eq $False} | Select-Object Name 
        $networkadapters = Get-WmiObject Win32_PerfRawData_NvspNicStats_HyperVVirtualNetworkAdapter | Select-Object Name
        $result = @()
        foreach ($networkadapter in $networkadapters) {
            foreach ($vm in $vms) {
                if ($networkadapter.Name -Match $vm.Name) {
                    $data = New-Object PSCustomObject
                    $data | Add-Member -type NoteProperty -name Perf  -Value $networkadapter.Name
                    $data | Add-Member -type NoteProperty -name Name  -Value $vm.Name
                    $result += $data
                }
            }
        }

        $result_json = [pscustomobject]@{
            'data' = @(
                $result | ForEach-Object {
                    [pscustomobject]@{
                        '{#VM_NETWORKADAPTER_NAME}' = $_.Name;
                        '{#VM_NETWORKADAPTER_PERF}' = $_.Perf;
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
    }

    # Discover in not clustered virtual machine's storage devices
    if ($Key -eq "vm_sd") {
        $vms = get-vm | Where-Object {$_.IsClustered -eq $False} | Select-Object Name 
        $networkadapters = Get-WmiObject Win32_PerfFormattedData_Counters_HyperVVirtualStorageDevice | Select-Object Name
        $result = @()
        foreach ($networkadapter in $networkadapters) {
            foreach ($vm in $vms) {
                if ($networkadapter.Name -Match $vm.Name) {
                    $data = New-Object PSCustomObject
                    $data | Add-Member -type NoteProperty -name Perf  -Value $networkadapter.Name
                    $data | Add-Member -type NoteProperty -name Name  -Value $vm.Name
                    $result += $data
                }
            }
        }

        $result_json = [pscustomobject]@{
            'data' = @(
                $result | ForEach-Object {
                    [pscustomobject]@{
                        '{#VM_STORAGEDEVICE_NAME}' = $_.Name;
                        '{#VM_STORAGEDEVICE_PERF}' = $_.Perf;
                    }
                }					
            )
        }| ConvertTo-Json
        [Console]::WriteLine($result_json)
        
    }
}

if ($ActionType -eq "get") {

    # Get data for physical network adapter by name
    if ($Key -eq "host_stat") {
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
            $VMsStateOther = 0

            foreach ($VM in $VMs) {  
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

    # get vm statistics
    if ($Key -eq "vm_stat") {
        if ($Value -ne "") {

            $VM = Get-VM -Name $Value
            # status , integration service, hearbeat, state, 
            $result = New-Object PSCustomObject
            $result | Add-Member -type NoteProperty -name Status  -Value $VM.Status
            $result | Add-Member -type NoteProperty -name State  -Value $VM.State
            $result | Add-Member -type NoteProperty -name IntegrationServicesVersion  -Value $VM.IntegrationServicesVersion
            $result | Add-Member -type NoteProperty -name ReplicationHealth  -Value $VM.ReplicationHealth
            $result | Add-Member -type NoteProperty -name ReplicationMode  -Value $VM.ReplicationMode
            $result | Add-Member -type NoteProperty -name ReplicationState  -Value $VM.ReplicationState
            $result | Add-Member -type NoteProperty -name VirtualMachineSubType  -Value $VM.VirtualMachineSubType
            $result | ConvertTo-Json
        }
    }

   
}
	
