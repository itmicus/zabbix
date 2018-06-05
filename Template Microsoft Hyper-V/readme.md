# Template Microsoft Hyper-V

# Features

Monitoring and LLD : Guest/Root CPU, RAM, Ratio CPU/RAM, Virtual Network adapters and switches   
Inventory:count VM,states, ratio, health  
Screen System performance: CPU, Memory, Networks  
Independent OS language  
Setting configuring by User Macros  

# Requirements
Hyper-V: Windows server 2008 R2 or higher  
PowerShell 3  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template

3. Create 2 folders in zabbix agent folder:
\scripts\  
\zabbix_agentd\  
and copy the files  
hyperv_host.ps1 to \scripts\  
hyperv_host.conf to \zabbix_agentd\  

4. Add lines to zabbix.conf

Include=C:\Program Files\zabbix-agent\zabbix_agentd\\*.conf  
UnsafeUserParameters=1  
Timeout=10  

5. Restart Zabbix Agent
6. All triggers you may change through user macros in host

# Articles for understanding how monitoring Hyper-V
WMI:
http://wutils.com/wmi/root/cimv2/win32_perfrawdata/

Main concept get from this blog:
https://blogs.msdn.microsoft.com/tvoellm/2009/04/22/monitoring-hyper-v-performance/

CPU
https://blogs.technet.microsoft.com/neales/2016/10/24/hyper-v-performance-cpu/

Memory
https://blogs.technet.microsoft.com/neales/2016/11/22/hyper-v-performance-memory/

Perf
https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/detecting-virtualized-environment-bottlenecks
