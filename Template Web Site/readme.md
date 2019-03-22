
# Template Web Site Metrics

This template for Zabbix Monitoring template.

# How to Install.

1. Copy website_metrics.py on your server to folder /usr/lib/zabbix/externalscripts/
2. Copy website_settings.example.py to website_settings.py to /usr/lib/zabbix/externalscripts/ and make proper changes on it 
3. Install Python module: pip install python-dateutil tldextract
4. Import the template XML file using the Zabbix Templates Import feature.
5. Create Host
6. Set template to host
7. Override in host macros:

{$WEBSITE_METRICS_URL} - full URL for check availability<br/>
{$WEBSITE_METRICS_PHRASE} - phrase, which Zabbix will be monitoring<br/>
{$WEBSITE_METRICS_DEBUG} - turn on debug information while script executing<br/>
{$WEBSITE_METRICS_TIMEOUT} - timeout in seconds for web site check<br/>
{$WEBSITE_METRICS_TIMEOUT_RECOVERY} - timeout in seconds for recovery<br/>

# Post about this template
https://itmicus.ru/news/zabbix-website-monitoring/

