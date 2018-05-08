# Template Windows OS Active

# Features

Monitoring and LLD :CPU, Memory, Physical disk, Logical Disk,  Physical Network adapter  
Inventory: Hardware, OS, Software  
Screen System performance: CPU, Memory, Disks, Networks  
Independent OS language  
Independent Physical and Virtual hardware  


# Requirements
Windows 7 or higher  
Windows server 2008 R2 or higher  
PowerShell 3  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template OS Windows Active

3. Create 2 folders in zabbix agent folder:
\scripts\<br/>
\zabbix_agentd\<br/>
and copy the files<br/>
os_windows_active.ps1 to \scripts\<br/>
os_windows_active.conf to \zabbix_agentd\<br/>

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\*.conf<br/>
UnsafeUserParameters=1<br/>

5. Restart Zabbix Agent

