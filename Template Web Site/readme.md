
# Template Web Site Metrics

This template for Zabbix Monitoring template.

# How to Install

1. Copy website_metrics.py on your server to ExternalScripts folder (/usr/lib/zabbix/externalscripts/ for default) and grant it executable:
chmod 755 website_metrics.py
2. Copy website_settings.example.py to ExternalScripts folder (/usr/lib/zabbix/externalscripts/ for default) and rename in to. Make proper changes on it.
3. Install python and pip if required.
For Ubuntu 18.04:
apt install python-pip
4. Install Python module:
pip install -r requirements.txt
5. Import the template XML file using the Zabbix Templates Import feature for your version of installation.
6. Create Host.
7. Link Template Website metrics to host.
7. Override in host macros:

{$WEBSITE_METRICS_URL} - full URL for check availability<br/>
{$WEBSITE_METRICS_PHRASE} - phrase, which Zabbix will be monitoring<br/>
{$WEBSITE_METRICS_DEBUG} - turn on debug information while script executing<br/>
{$WEBSITE_METRICS_TIMEOUT} - timeout in seconds for web site check<br/>
{$WEBSITE_METRICS_TIMEOUT_RECOVERY} - timeout in seconds for recovery<br/>

# Post about this template
https://itmicus.ru/news/zabbix-website-monitoring/

