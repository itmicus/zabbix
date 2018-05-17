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



## Template Microsoft Hyper-V
Main template for discover Hyper-V infrastructure on cluster or standalone hypervisor.  
### LLD  
Discover Hyper-V clusters  
Name: hyperv[discover, cluster]   
Type: Zabbix agent (Active)  
Period: 1d  
Description: Discover cluster  
Filter: "{#CLUSTER_FQDN}"  

Host prototypes  
Discover create host for cluster and set template  
Hyper-V Cluster "{#CLUSTER_FQDN}"  
Template: Template Microsoft Hyper-V Cluster  
Возможно тут будет как обычно засада, это вирутальных хост, без zabix agenta. Эта данные надо передавать через trapper, пока надо подумать как сделать через zabbix active  
  
Discover Hyper-V hypervisors  
Name: hyperv[discover, hv]  
Type: Zabbix agent (Active)  
Description: Discover cluster node or standalone hypervisor  
Period: 1d  
Host prototypes  
"{#HV _FQDN}"  
Template: Template Microsoft Hyper-V Hypervisor  
  
Discover Hyper-V VMs  
Name: hyperv[discover, vm]  
Type: Zabbix agent (Active)  
Description: Discover VM on cluster or standalone hypervisor  
Period: 1d  
Host prototypes  
{#VM.NAME}  
Template: Template Microsoft Hyper-V Vm  
  
## Template Microsoft Hyper-V Cluster  
Template for monitoring Microsoft Failover cluster with Hyper-V role.  

## Template Microsoft Hyper-V Hypervisor  
Template for monitoring node from Microsoft Failover cluster with Hyper-V role or standalone Hyper-V.  

## Template Microsoft Hyper-V VMs  
Template for monitoring each VM in cluster or standalone.   


