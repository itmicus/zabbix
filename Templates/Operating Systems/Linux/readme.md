# Template OS Linux by Zabbix agent active

## Overview

This template works only Zabbix server 4.2 or higher

- Monitoring Linux components: CPU, Memory, Disk, Network, Inventory
- Templates follow Zabbix template guidelines (https://www.zabbix.com/documentation/4.4/manual/appendix/templates/template_guidelines)
  
## Requirements

- Ubuntu/CentOS/Redhat

## Setup

1. Import the template XML file template_os_linux_by_zabbix_agent_active.xml using the Zabbix Templates Import feature to group Templates/Operating Systems

2. Create host and set Template OS Linux by Zabbix agent active

3. Create new folder `zabbix_agent.d` in /etc/zabbix/

4. Copy all files *.conf to /etc/zabbix/zabbix_agent.d/  

5. Add lines to zabbix.conf

    ```
    Include=Include=/etc/zabbix/zabbix_agentd.d  
    Timeout=5
    ```

6. Restart Zabbix Agent  

7. All triggers you may change through user macros in host

## Template links

The template included follow templates:

- Template OS Linux CPU by Zabbix agent active
- Template OS Linux Disk by Zabbix agent active
- Template OS Linux Disk Performance by Zabbix agent active
- Template OS Linux Inventory by Zabbix agent active
- Template OS Linux Memory by Zabbix agent active
- Template OS Linux Network by Zabbix agent active

## Discovery rules

- Disk discovery - physical disk discovery for monioring disk performance
- Mounted filesystem discovery
- Network interface discovery

## Feedback

Email: [Itmicus](mailto:info@itmicus.ru)

Issues: https://github.com/itmicus/zabbix/issues
