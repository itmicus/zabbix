# Template OS Windows by Zabbix agent active

## Overview

This template works only Zabbix server 4.2 or higher

- Monitoring Windows components: CPU, Memory, Disk, Network, Inventory
- Templates follow Zabbix template guidelines (https://www.zabbix.com/documentation/4.4/manual/appendix/templates/template_guidelines)
  
## Requirements
  
- Windows 7 or later with latest service pack  
- Windows Server 2008 or later with latest service pack  
- **PowerShell 3 or higher**  

## Setup

1. Import the template XML file template_os_windows_by_zabbix_agent_active.xml using the Zabbix Templates Import feature to group Templates/Operating Systems

2. Create host and set Template OS Windows by Zabbix agent active

3. Create new folder `zabbix_agent.d` in <path_to_your_zabbix_agent_folder>\

4. Copy all files *.conf to <path_to_your_zabbix_agent_folder>\zabbix_agent.d\  

5. Add lines to zabbix.conf

    ```
    Include=<path_to_your_zabbix_agent_folder>\zabbix_agent.d\  
    Timeout=5
    ```

6. Restart Zabbix Agent  

7. All triggers you may change through user macros in host

## Template links

The template included follow templates:

- Template OS Windows CPU by Zabbix agent active
- Template OS Windows Disk by Zabbix agent active
- Template OS Windows Disk Performance by Zabbix agent active
- Template OS Windows Inventory by Zabbix agent active
- Template OS Windows Memory by Zabbix agent active
- Template OS Windows Network by Zabbix agent active

## Discovery rules

- Disk discovery - physical disk discovery for monioring disk performance
- Mounted filesystem discovery
- Network interface discovery

## Feedback

Email: [Itmicus](mailto:info@itmicus.ru)

Issues: https://github.com/itmicus/zabbix/issues
