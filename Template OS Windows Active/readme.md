#
# Template Windows OS Active
#

1. Import the template XML file using the Zabbix Templates Import feature.
2. Create 2 folders in zabbix agent folder:
scripts
zabbix_agentd

3. Copy os_windows_active.ps1 to \scripts\
4. Copy os_windows_active.conf to \zabbix_agentd\

5. ZABBIX.CONF additional lines

### Option: Include
#	You may include individual files in the configuration file.
#
# Mandatory: no
# Default:
# Include=

# Include=c:\zabbix\zabbix_agentd.userparams.conf
# Include=c:\zabbix\zabbix_agentd.conf.d\
Include=C:\Program Files\zabbix-agent\zabbix_agentd\*.conf

### Option: UnsafeUserParameters
#	Allow all characters to be passed in arguments to user-defined parameters.
#	The following characters are not allowed:
#	\ ' " ` * ? [ ] { } ~ $ ! & ; ( ) < > | # @
#	Additionally, newline characters are not allowed.
#	0 - do not allow
#	1 - allow
#
# Mandatory: no
# Range: 0-1
# Default:
UnsafeUserParameters=1


6. Restart zabbix agent