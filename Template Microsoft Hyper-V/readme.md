# Template Microsoft Hyper-V

# Features

Monitoring and LLD :
Independent OS language  
 


# Requirements
Windows 7 or higher  
Windows server 2008 R2 or higher  
PowerShell 3  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template

3. Create 2 folders in zabbix agent folder:
\scripts\  
\zabbix_agentd\  
and copy the files  
active_os_windows.ps1 to \scripts\  
active_os_windows.conf to \zabbix_agentd\  

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\\*.conf  
UnsafeUserParameters=1  
Timeout=10  

5. Restart Zabbix Agent
6. All critiacal triggers you may 

# Post about this template


