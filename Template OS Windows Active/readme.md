# Template Windows OS Active

# Features

Monitoring:
CPU
Memory
Physical disk
Logical Disk
Physical Network adapter

Inventory: Hardware, OS, Software
Screen: System performance CPU, Memory, Disks, Networks

Independent OS language


# Requirements
Windows 7 or higher
Windows server 2008 R2 or higher
PowerShell 3

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template OS Windows Active

3. Create 2 folders in zabbix agent folder:
\scripts\
\zabbix_agentd\
and copy the files
os_windows_active.ps1 to \scripts\
os_windows_active.conf to \zabbix_agentd\

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\*.conf
UnsafeUserParameters=1

5. Restart Zabbix Agent

