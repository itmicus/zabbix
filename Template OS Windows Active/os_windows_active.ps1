
#requires -version 3

<#
.SYNOPSIS
	This script part of the Zabbix 
    Tempalte Windows OS Active
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
  Creation Date:  07/05/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  os_windows_active.ps1 -ActionType "$1" -Key "$2" -Value "$3"
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


function Test-VM {

    $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem 
    $IsVM = $false      
    switch ($ComputerSystemInfo.Model) { 
                     
        # Check for Hyper-V Machine Type 
        "Virtual Machine" { 
            $MachineType = "VM" 
            $IsVM = $true
        } 
 
        # Check for VMware Machine Type 
        "VMware Virtual Platform" { 
            $MachineType = "VM" 
            $IsVM = $true
        } 
 
        # Check for Oracle VM Machine Type 
        "VirtualBox" { 
            $MachineType = "VM" 
            $IsVM = $true
        } 
 
        # Check for Xen 
        # I need the values for the Model for which to check. 
 
        # Check for KVM 
        # I need the values for the Model for which to check. 
 
        # Otherwise it is a physical Box 
        default { 
            $MachineType = "Physical" 
        } 
    } 
    return $IsVM
}


function Get-Chassis {  
      
    $chassis = Get-WmiObject win32_systemenclosure | Select-Object chassistypes  
    $result = ""
    switch ($chassis.chassistypes) { 
        "3" {  $result = "Desktop"} 
        "4" {  $result = "Low Profile Desktop"} 
        "5" {  $result = "Pizza Box"} 
        "6" {  $result = "Mini Tower"}  
        "7" {  $result = "Tower"} 
        "8" {  $result = "Portable"}  
        "9" {  $result = "Laptop"} 
        "10" {  $result = "Notebook"}  

        "11" {  $result = "Hand Held"}  
        "12" {  $result = "Docking Station"}  
        "13" {  $result = "All in One"}  
        "14" {  $result = "Sub Notebook"}  
        "15" {  $result = "Space-Saving"}  
        "16" {  $result = "Lunch Box"}  
        "17" {  $result = "Main System Chassis"}  

        "18" {  $result = "Expansion Chassis" }  
        "19" {  $result = "Sub Chassis"}  
        "20" {  $result = "Bus Expansion Chassis"}  
        "21" {  $result = "Peripheral Chassis"}  
        "22" {  $result = "Storage Chassis"}  
        "23" {  $result = "Rack Mount Chassis"}  
        "24" {  $result = "Sealed-Case PC"}  

        "26" {  $result = "Compact PCI"}  
        "27" {  $result = "Advanced TCA"}  
        "28" {  $result = "Blade"}  
        "29" {  $result = "Blade Enclosure"}  
        "30" {  $result = "Tablet"}  
        "31" {  $result = "Convertible"}  
        "32" {  $result = "Detachable"}  
        "33" {  $result = "IoT Gateway"}  
        "34" {  $result = "Embedded PC"}  
        "35" {  $result = "Mini PC"}  
        "36" {  $result = ""}  

        default {  $result = "Unknown"} 
    }    
    return $result 
}  

Function Get-FirewallState {
    [CmdletBinding()]
	
    $ErrorActionPreference = "Stop"
    Try {

        $HKLM = 2147483650
        $reg = get-wmiobject -list -namespace root\default  | where-object { $_.name -eq "StdRegProv" }
        $DomainProfileEnabled = $reg.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile", "EnableFirewall")
        $DomainProfileEnabled = [int]($DomainProfileEnabled.uValue)
        $PrivateProfileEnabled = $reg.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PrivateProfile", "EnableFirewall")
        $PrivateProfileEnabled = [int]($PrivateProfileEnabled.uValue)
        $PublicProfileEnabled = $reg.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile", "EnableFirewall")
        $PublicProfileEnabled = [int]($PublicProfileEnabled.uValue)
        $FirewallObject = New-Object PSObject
        Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "DomainProfile" -value $DomainProfileEnabled 
        Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "PrivateProfile" -value $PrivateProfileEnabled  
        Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "PublicProfile" -value $PublicProfileEnabled 
        return $FirewallObject
    }
    Catch {
        Write-Host  ($_.Exception.Message -split ' For')[0] -ForegroundColor Red
    }
}

function Get-LatestUpdate {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Update.Session') | Out-Null
    $Session = New-Object -ComObject Microsoft.Update.Session                    
    $UpdateSearcher = $Session.CreateUpdateSearcher()
    $NumUpdates = $UpdateSearcher.GetTotalHistoryCount()
    $InstalledUpdates = $UpdateSearcher.QueryHistory(1, $NumUpdates)
    $LastInstalledUpdate = $InstalledUpdates | Select-Object Title, Date | Sort-Object -Property Date -Descending | Select-Object -first 1

    return $LastInstalledUpdate.Date
}
	
if ($ActionType -eq "discover") {
    # Discover physical disk
    if ($Key -eq "pdisk") {
        [pscustomobject]@{
            'data' = @(
                Get-WmiObject win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where-Object {$_.name -ne "_Total"} | ForEach-Object {
                    [pscustomobject]@{ '{#PHYSICAL_DISK}' = $_.Name }
                }
            )
        } | ConvertTo-Json
    }

    # Discover logical disk
    if ($Key -eq "ldisk") {
        [pscustomobject]@{
            'data' = @(
                Get-WmiObject win32_logicaldisk| Where-Object {$_.drivetype -eq 3}| ForEach-Object {
                    [pscustomobject]@{
                        '{#LOGICAL_DISK}'             = $_.DeviceID
                        '{#LOGICAL_DISK_VOLUME_NAME}' = $_.VolumeName					
                    }
                }
            )
        } | ConvertTo-Json
		
    }


    # Discover network physical interface
    if ($Key -eq "pnetwork") {	
	
        <#
			Query for the instances of Win32_NetworkAdapter that you are interested in.
		Take the value of 'PNPDeviceID' from each Win32_NetworkAdapter and append it to "\HKLM\SYSTEM\CurrentControlSet\Enum\" to produce a registry path to information on the adapter. Here is an example: "\HKLM\SYSTEM\CurrentControlSet\Enum\PCI\VEN_8086&DEV_100E&SUBSYS_001E8086&REV_02\3&267A616A&0&18".
		Query the registry for the "FriendlyName" key at the path you derived above.
		If the "FriendlyName" key is present then take its string value. If the "FriendlyName" key is not defined then instead use the value of the "Description" key from Win32_NetworkAdapter.
		Take the string you got in step #4 and replace all instances of "/" and "#" with an underscore "_".
		The resulting string from step #5 should match the "Name" property within Win32_PerfFormattedData_Tcpip_NetworkInterface.
        #>
        
        # check is vm or physical, because on physical need search pnp like PCI card
        if (Test-VM) {
            $filter = "NetEnabled='True' and  PhysicalAdapter='True' and not NetConnectionID like ''"

        }
        else {
            $filter = "NetEnabled='True' and  PhysicalAdapter='True' 
						and NOT Manufacturer ='Microsoft' 
                		AND NOT PNPDeviceID LIKE 'ROOT\\%'"
        }

        $result_json = [pscustomobject]@{
            'data' = @(
                get-wmiobject win32_networkadapter -Filter $filter | ForEach-Object {
                    $PHYSICAL_NETWORK_NAME = $_.NetConnectionID;
                    $PHYSICAL_NETWORK_INTERFACEINDEX = $_.InterfaceIndex;
                    Get-WmiObject Win32_PnPEntity -Filter ("PNPDeviceID='$($_.PNPDeviceID)'" -Replace '\\', '\\') | ForEach-Object { 
                        [pscustomobject]@{
                            '{#PHYSICAL_NETWORK_NAME}'           = $PHYSICAL_NETWORK_NAME;
                            '{#PHYSICAL_NETWORK_NAME_PERF}'      = $_.Name.Replace("/", "_").Replace("#", "_").Replace("(", "[").Replace(")", "]")
                            '{#PHYSICAL_NETWORK_INTERFACEINDEX}' = $PHYSICAL_NETWORK_INTERFACEINDEX
                        }
                    }
                }					
            )
        }| ConvertTo-Json
	
        # output though console with encoding UTF8, because name can be with non english  characters
        [Console]::WriteLine($result_json)
    }


    # Discover windows network nic teaming - logical network
    if ($Key -eq "lnetwork") {
        $result_json = [pscustomobject]@{
            'data' = @(
                Get-NetLbfoTeam | ForEach-Object {
                    [pscustomobject]@{
                        '{#LNETWORK}' = $_.Name
                    }
                }
            )
        } | ConvertTo-Json
        [Console]::WriteLine($result_json)
    }
}

if ($ActionType -eq "get") {

    # Get data for physical network adapter by name
    if ($Key -eq "pnetwork") {
        if ($value -ne "") {
            $adapter = get-wmiobject win32_networkadapter  -Filter "NetEnabled='True' and  PhysicalAdapter='True'" |  Where-Object {$_.Name -eq "$Value"} | Select-Object *
            $connection_status = Get-NetworkStatusFromValue -SV ([convert]::ToInt32($adapter.NetConnectionStatus))
				
            $result = New-Object PSCustomObject
            $result | Add-Member -type NoteProperty -name MacAddress  -Value $adapter.MACAddress
            $result | Add-Member -type NoteProperty -name LinkSpeed -Value ([convert]::ToInt32($adapter.Speed))
            $result | Add-Member -type NoteProperty -name Name -Value $adapter.NetConnectionID
            $result | Add-Member -type NoteProperty -name InterfaceIndex -Value $adapter.Index
            $result | Add-Member -type NoteProperty -name Status -Value $connection_status
            $result | Add-Member -type NoteProperty -name AdminStatus -Value $adapter.NetEnabled
            $result | ConvertTo-Json
	
        }
    }

    if ($Key -eq "lnetwork") {
        if ($value -ne "") {
		
            $adapter = get-wmiobject win32_networkadapter  -Filter "NetEnabled='True' and  PhysicalAdapter='True'" |  Where-Object {$_.Name -eq "$Value"} | Select-Object *
            $connection_status = Get-NetworkStatusFromValue -SV ([convert]::ToInt32($adapter.NetConnectionStatus))
				
            $result = New-Object PSCustomObject
            $result | Add-Member -type NoteProperty -name MacAddress  -Value $adapter.MACAddress
            $result | Add-Member -type NoteProperty -name LinkSpeed -Value ([convert]::ToInt32($adapter.Speed))
            $result | Add-Member -type NoteProperty -name Name -Value $adapter.NetConnectionID
            $result | Add-Member -type NoteProperty -name InterfaceIndex -Value $adapter.Index
            $result | Add-Member -type NoteProperty -name Status -Value $connection_status
            $result | Add-Member -type NoteProperty -name AdminStatus -Value $adapter.NetEnabled
            $result | ConvertTo-Json
	
        }
    }
	
    if ($Key -eq "system_status") {
		
        $LastBootUpTime = (Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL = 'LastBootUpTime'; EXPRESSION = {$_.ConverttoDateTime($_.lastbootuptime)}}).LastBootUpTime
        $LocalTime = Get-Date
        $PSComputername = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty PSComputername
        $Caption = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption
        $OSArchitecture = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture
        $Manufacturer = Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty Manufacturer
        $SerialNumber = Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty SerialNumber

        $result = New-Object PSCustomObject
        $result | Add-Member -type NoteProperty -name Name -Value $PSComputername
        $result | Add-Member -type NoteProperty -name Caption -Value $Caption
        $result | Add-Member -type NoteProperty -name OSArchitecture  -Value $OSArchitecture
        $result | Add-Member -type NoteProperty -name Manufacturer -Value $Manufacturer
        $result | Add-Member -type NoteProperty -name SerialNumber -Value $SerialNumber
        $result | Add-Member -type NoteProperty -name LastBootUpTime -Value $LastBootUpTime
        $result | Add-Member -type NoteProperty -name LocalTime -Value $LocalTime  
        $result | ConvertTo-Json
	
    }
	
    if ($Key -eq "inventory") {

        $result = New-Object PSCustomObject

        ######################  host
        $hostname = $env:COMPUTERNAME
        $result | Add-Member -type NoteProperty -name Hostname  -Value $hostname
    
        ######################  get serial number and bios
        $bios = (Get-WmiObject win32_bios)
        $bios_Manufacturer = $bios.Manufacturer
        $bios_Version = $bios.Name
        $computer_serialNumber = $bios.serialnumber
        $bios_SMBIOSBIOSVersion = $bios.SMBIOSBIOSVersion

        $result | Add-Member -type NoteProperty -name BiosManufacturer -Value $bios_Manufacturer
        $result | Add-Member -type NoteProperty -name BiosVersion -Value $bios_Version 
        $result | Add-Member -type NoteProperty -name SMBIOSBIOSVersion -Value  $bios_SMBIOSBIOSVersion
        $result | Add-Member -type NoteProperty -name SerialNumber -Value $computer_serialNumber

        ######################  os
        $os = Get-WmiObject Win32_OperatingSystem
        $os_vendor = $os.Manufacturer
        $os_buildversion = $os.BuildNumber
        $os_Version = $os.Version
        $os_title = $os.Caption
        $os_installdate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($(get-itemproperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate)) 
        $BootTime = $os.ConvertToDateTime($os.LastBootUpTime) 
        $Uptime = [math]::Round( ($os.ConvertToDateTime($os.LocalDateTime) - $boottime).TotalSeconds)
        $update_latest_date = Get-LatestUpdate
        $StartDate = (GET-DATE)
        $update_latest_seconds = [math]::Round(($StartDate - $update_latest_date).TotalSeconds)

        $result | Add-Member -type NoteProperty -name OSVendor -Value $os_vendor
        $result | Add-Member -type NoteProperty -name OSBuildversion -Value $os_buildversion
        $result | Add-Member -type NoteProperty -name OSVersion -Value $os_Version
        $result | Add-Member -type NoteProperty -name OSTitle -Value $os_title
        $result | Add-Member -type NoteProperty -name OSInstallDate -Value $os_installdate.tostring("dd.MM.yyyy")
        $result | Add-Member -type NoteProperty -name OSLatestUpdatesInstalled -Value $update_latest_date.tostring("dd.MM.yyyy")
        $result | Add-Member -type NoteProperty -name OSSecondsFromLatestUpdatesInstalled -Value $update_latest_seconds
        $result | Add-Member -type NoteProperty -name OSUptime  -Value  $Uptime

        ###################### cpu
        $cpu_atchitecture = $ENV:PROCESSOR_ARCHITECTURE
        $cpu_model = (Get-WmiObject -class win32_processor).Name
        $result | Add-Member -type NoteProperty -name CPUModel -Value $cpu_model
        $result | Add-Member -type NoteProperty -name ComputerArchitecture -Value $cpu_atchitecture

        ######################  memory
        $TotalVisibleMemorySize = $os.TotalVisibleMemorySize * 1024 # in bytes
        $result | Add-Member -type NoteProperty -name TotalPhysicalMemory -Value $TotalVisibleMemorySize

        ######################  powershell version
        $env = $PSVersionTable
        $shell_versions = New-Object PSCustomObject
        $shell_versions  | Add-Member -type NoteProperty -name PowerShell  -Value $env.PSVersion.ToString()
        $shell_versions  | Add-Member -type NoteProperty -name CLR  -Value $env.CLRVersion.ToString()

        ### check psremoting
        $psremoting_active = $false
        $test = [bool](Test-WSMan -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue)
        if ($test -eq $true) {
            $psremoting_active = 1
        }
        else {
            $psremoting_active = 0
        }

        ### get zabbix agent version
        $zabbix_service_path = (Get-WmiObject win32_service | Where-Object {$_.name -eq 'Zabbix Agent'} ).pathname
        $zabbix_agent_path = $zabbix_service_path.substring(0, $zabbix_service_path.IndexOf("--config")).replace("""", "")
        $zabbix_version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($zabbix_agent_path).FileVersion
        $shell_versions  | Add-Member -type NoteProperty -name PSRemotingActive -Value $psremoting_active     

        $result | Add-Member -type NoteProperty -name ShellVersion  -Value  $shell_versions 
        $result | Add-Member -type NoteProperty -name ZabbixAgentVersion -Value $zabbix_version

        ######################  physical
        $computer = Get-WmiObject Win32_Computersystem
        $computer_domain = $computer.domain
        $chassis = Get-Chassis
        $motherboadr = Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer, Product

        $result | Add-Member -type NoteProperty -name Domain  -Value $computer_domain
        $result | Add-Member -type NoteProperty -name ComputerManufacturer  -Value $computer.Manufacturer
        $result | Add-Member -type NoteProperty -name ComputerModel  -Value $computer.Model
        $result | Add-Member -type NoteProperty -name ComputerNumberOfLogicalProcessors  -Value $computer.NumberOfLogicalProcessors
        $result | Add-Member -type NoteProperty -name ComputerNumberOfProcessors  -Value $computer.NumberOfProcessors
        $result | Add-Member -type NoteProperty -name Chassis  -Value     $chassis 
        $result | Add-Member -type NoteProperty -name MotherboardManufacturer -Value $motherboadr.Manufacturer
        $result | Add-Member -type NoteProperty -name MotherboardProduct -Value $motherboadr.Product 

        ###################### firewall
        $firewall_status = Get-FirewallState 
        $result | Add-Member -type NoteProperty -name FirewallStatus -Value   $firewall_status


        ###################### network
        #$mac_addresses = ""
        #Get-WmiObject win32_networkadapterconfiguration | select description, macaddress| % { $mac_addresses = $mac_addresses + $_.description + ":" + $_.macaddress + ";" }
        #$gateways = ""
        #Get-NetIPConfiguration |  Foreach IPv4DefaultGateway | % { $gateways = $gateways + $_.NextHop + "," + $_.DestinationPrefix + "," + $_.RouteMetric + "," + $_.ifIndex + ";"  }
        #$ips = ""
        #Get-NetIPConfiguration |  Foreach IPv4Address | % { $ips = $ips + $_.IPAddress + ";"  }
    
        $nwINFO = Get-WmiObject  Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null } | Select-Object IPAddress, IpSubnet, DefaultIPGateway, MACAddress, DNSServerSearchOrder
        $result | Add-Member -type NoteProperty -name Networks -Value $nwINFO 


        ###################### antivirus
        $AntiVirusProduct = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        switch ($AntiVirusProduct.productState) { 
            "262144" {$defstatus = "Up to date" ; $rtstatus = 0} 
            "262160" {$defstatus = "Out of date" ; $rtstatus = 0} 
            "266240" {$defstatus = "Up to date" ; $rtstatus = 1} 
            "266256" {$defstatus = "Out of date" ; $rtstatus = 1} 
            "393216" {$defstatus = "Up to date" ; $rtstatus = 0} 
            "393232" {$defstatus = "Out of date" ; $rtstatus = 0} 
            "393488" {$defstatus = "Out of date" ; $rtstatus = 0} 
            "397312" {$defstatus = "Up to date" ; $rtstatus = 1} 
            "397328" {$defstatus = "Out of date" ; $rtstatus = 1} 
            "397584" {$defstatus = "Out of date" ; $rtstatus = 1} 
            "397568" {$defstatus = "Up to date"; $rtstatus = 1}
            "393472" {$defstatus = "Up to date" ; $rtstatus = 0}
            default {$defstatus = "Unknown" ; $rtstatus = -1} 
        }

        $antivirus = New-Object PSCustomObject
        $antivirus  | Add-Member -type NoteProperty -name ProductName -Value   $AntiVirusProduct.displayName
        $antivirus  | Add-Member -type NoteProperty -name ProductExe -Value   $AntiVirusProduct.pathToSignedProductExe
        $antivirus  | Add-Member -type NoteProperty -name ProductUpdateStatus -Value   $defstatus
        $antivirus  | Add-Member -type NoteProperty -name ProductRealTimeProtection -Value   $rtstatus
        $result | Add-Member -type NoteProperty -name Antivirus -Value $antivirus
        $result | ConvertTo-Json
    }
}
	
