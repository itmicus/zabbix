# Template Microsoft Windows Certificates

# Features

Monitoring and LLD : local machine certificates, days to expire
Independent OS language  
Setting configuring by User Macros  


# Requirements
Windows 7 or higher  
Windows server 2008 R2 or higher  
PowerShell 3 or higher  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template

3. Create 2 folders in zabbix agent folder:
\scripts\  
\zabbix_agentd\  
and copy the files  
windows_certs.ps1 to \scripts\  
windows_certs.conf to \zabbix_agentd\  

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\\*.conf  
UnsafeUserParameters=1  
Timeout=10

5. Restart Zabbix Agent
6. All triggers you may change through user macros in host

# Post about this template
