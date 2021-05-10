# Template Microsoft Hyper-V

# Features

* Monitoring and LLD: Guest/Root CPU, RAM, Ratio CPU/RAM, Host Virtual Network adapters and switches, Virtual machine storage and network
* Inventory: count VM, states, health  
* Screen System performance: CPU, Memory, Networks, VHDX 
* Independent OS language  
* Setting configuring by User Macros  
* You can analyzing all performance data overall host and virtual machines

# Requirements
* Hyper-V: Windows server 2008 R2 or higher  
* PowerShell 3  

# Install
1. On the server, import the template XML file using the Zabbix Templates Import feature (Administration > Proxies > Create proxy)

2. On the server, create Host and set Template

3. On the client, enter in `C:\Program Files\Zabbix Agent` and create 2 directories:

* `\scripts\`
    * Then copy the `.ps1` file here
* `\zabbix_agentd\`
    * Then copy the `.conf` file here

At the end you should have:

* `C:\Program Files\Zabbix Agent\scripts\hyperv_host.ps1`
* `C:\Program Files\Zabbix Agent\zabbix_agentd\hyperv_host.conf`

4. On the client, add these lines to your `zabbix_agentd.conf`:

```
Include=C:\Program Files\Zabbix Agent\*.conf  
UnsafeUserParameters=1  
Timeout=10
```

5. Restart Zabbix Agent
6. All triggers you may change through user macros in host

# Post about this template
https://itmicus.ru/news/monitoring-microsoft-hyper-v-zabbix/


# Articles for understanding how monitoring Hyper-V
## WMI  
http://wutils.com/wmi/root/cimv2/win32_perfrawdata/  

## Main concept get from this blog  
https://blogs.msdn.microsoft.com/tvoellm/2009/04/22/monitoring-hyper-v-performance/  

## CPU  
https://blogs.technet.microsoft.com/neales/2016/10/24/hyper-v-performance-cpu/  

## Memory  
https://blogs.technet.microsoft.com/neales/2016/11/22/hyper-v-performance-memory/  

## Perf    
https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/detecting-virtualized-environment-bottlenecks  
