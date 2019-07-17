# Template Linux

# Features

Monitoring Linux: cpu, mem, disk, net   


# Requirements
Linux  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template

3. Create 2 folders in zabbix agent folder:
\scripts\  
\zabbix_agentd\  
and copy the files  
*.conf to \zabbix_agentd\  

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\\*.conf  
UnsafeUserParameters=1  
Timeout=10

5. Restart Zabbix Agent
6. All triggers you may change through user macros in host