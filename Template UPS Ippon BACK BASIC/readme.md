# Template UPS Ippon BACK BASIC

# Features
Monitoring: input, output voltage, battery voltage and temperature, load  
 
# Requirements
Windows 7 or higher  
Windows server 2008 R2 or higher  

# How install
1. Import the template XML file using the Zabbix Templates Import feature.

2. Create host and set Template UPS Ippon BACK BASIC  

3. Install on host Winpower Manager http://ippon.ru/support/documentation/  

4. Add lines to zabbix.conf  

Include=C:\Program Files\zabbix-agent\zabbix_agentd\\*.conf  
UnsafeUserParameters=1  
Timeout=10  

5. Restart Zabbix Agent  

# Post about this template
https://itmicus.ru/ups-ippon-back-basic-zabbix-monitoring  


