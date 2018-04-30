#!/usr/bin/python
# -*- coding: utf-8 -*-
import argparse
import json
import logging
import requests
import socket
import ssl
import subprocess
import sys
import time
import tldextract
from base64 import b64encode
from datetime import datetime
from dateutil import parser, relativedelta

try:
    from urllib.parse import urlparse #python3
except ImportError:
     from urlparse import urlparse #python2

# custom settings
import website_settings

__author__ = "Pavel Kuznetsov - https://itmicus.ru"
__copyright__ = "Copyright 2018, Itmicus LLC, Pavel Kuznetsov"
__license__ = "Mozilla Public License"
__version__ = "0.9"
__email__ = "p.kuznetsov@itmicus.ru"
__status__ = "Production ready"
__doc__ = """This script is part of Template_Website_metrics.xml Zabbix Monitoring template.
            It uses LLD for Domain name, SSL certificate check and website availability.

            Install: 

            1. Install requirements Python modules:
            pip install -r requirements.txt

            2. Copy website_settings.example.py to website_settings.py and make proper changes on it

            TODO:
            1. pyOpenSSL brokes sock.getpeercert() and --testssl not work

            """


# this code need to add cert properties for SSL connection inside response
HTTPResponse = requests.packages.urllib3.response.HTTPResponse #python2/3

orig_HTTPResponse__init__ = HTTPResponse.__init__

def new_HTTPResponse__init__(self, *args, **kwargs):
    orig_HTTPResponse__init__(self, *args, **kwargs)
    try:
        self.peercert = self._connection.sock.getpeercert()
    except AttributeError:
        pass

HTTPResponse.__init__ = new_HTTPResponse__init__

HTTPAdapter = requests.adapters.HTTPAdapter
orig_HTTPAdapter_build_response = HTTPAdapter.build_response


def new_HTTPAdapter_build_response(self, request, resp):
    response = orig_HTTPAdapter_build_response(self, request, resp)
    try:
        response.peercert = resp.peercert
    except AttributeError:
        pass
    return response


HTTPAdapter.build_response = new_HTTPAdapter_build_response


def zbx_sender(zbx_hostname, data):
    """
    Sending data to Zabbix server via zabbix_sender utility.
    :param zbx_hostname: HostName as zabbix server configuration
    :param data: array of [[zabbix item, value], [zabbix item, value]]
    :return:
       return output from zabbix_sender command
    """
    cmd = [website_settings.zabbix_sender_config['zbx_sender'], '-z', website_settings.zabbix_sender_config['zbx_server'],
           '-p', website_settings.zabbix_sender_config['zbx_server_port'], '-r', '-i', '-']

    if logging.getLevelName(logging.getLogger().getEffectiveLevel()) == 'DEBUG':
        cmd.insert(1, '-vv')

    fmt = "{host} {key} {value}"
    values_list = [fmt.format(host=zbx_hostname, key=v[0], value=v[1])
                   for v in data]
    values = "\n".join(values_list)

    logging.debug('Zabbix sender:' + str(cmd))
    logging.debug('Items: ' + str(values))

    p = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = p.communicate(input=values.encode('utf8'))
    out = result[0]+result[1]

    logging.debug('Zabbix sender result: ' + str(out))

    return out.decode('utf8')


class WebSiteCheck:
    """
    Checks domain, certificate, website
    """
    use_proxy = False
    http_proxy = ''
    proxies = {}
    session = None

    def __init__(self, http_proxy, use_proxy):
        self.http_proxy = http_proxy
        self.use_proxy = use_proxy
        self.session = requests.session()

        if use_proxy and http_proxy is not None:
            self.proxies = {
                "http": "http://{0}/".format(self.http_proxy),
                "https": "https://{0}/".format(self.http_proxy)
            }
            self.session.proxies.update(self.proxies)

    def discovery_domain(self, url):
        domain_name = tldextract.extract(url)
        return domain_name.registered_domain

    def discovery_ssl(self, url):
        o = urlparse(url)
        hostname = o.hostname
        port = 443

        if hostname is None:
            print("Check URL address, https://test.com")
            return

        if o.port is not None:
            port = o.port
        if o.scheme == 'https' and o.port is None:
            port = 443

        url = 'https://{0}:{1}'.format(hostname, port)

        cert_is_valid = self.ssl_verify_cert(url)
        if cert_is_valid == 1:
            return url
        else:
            return None

    def ssl_get_status(self, url):
        logging.debug('ssl_get_status:'+str(url))
        response = self.session.get(url, verify=True, timeout=(5, 10))
        logging.debug('Response:'+str(response))
        if hasattr(response, 'peercert') is False:
            logging.debug('Field peercert not found!')
            return None

        if response.peercert is not None:
            expire_date = parser.parse(response.peercert['notAfter'])
            logging.debug('Expire date: '+str(expire_date.replace(tzinfo=None)))
            expire_in = expire_date.replace(tzinfo=None) - datetime.utcnow().replace(tzinfo=None)
            logging.debug('Expire in: '+str(expire_in))
            days_to_expire = 0
            if expire_in.days > 0:
                days_to_expire = expire_in.days

            subject = dict(x[0] for x in response.peercert['subject'])
            issued_to = subject['commonName']
            issuer = dict(x[0] for x in response.peercert['issuer'])
            issued_by = issuer['commonName']
            notBefore = parser.parse(response.peercert['notBefore'])
            data = {
                'common_name': issued_to,
                'issued_by': issued_by,
                'issued_date': notBefore,
                'expiry_date': expire_date,
                'days_to_expire': days_to_expire,
                'serial_number': response.peercert['serialNumber'],
            }
            logging.debug('Return data:'+str(data))
            return data

    def ssl_verify_cert(self, url):
        try:
            self.session.get(url, verify=True, timeout=(5, 5))
            logging.debug('ssl_verify_cert: OK')
            return 1
        except Exception as e:
            logging.debug('Error: ' + str(e))
            return 0

    def domain_get_status(self, domain):
        headers = {
            "Accept": "application/json",
            "Authorization": "Token token=" + website_settings.JSONWHOIS_API
        }

        domain_info = self.session.get(
            "https://jsonwhois.com/api/v1/whois",
            headers=headers,
            data={'domain': domain})
        domain_info = json.loads(domain_info.text)
        logging.debug('Domain check result ' + str(domain_info))

        notBefore = parser.parse(domain_info['created_on'])
        expire_date = parser.parse(domain_info['expires_on'])
        expire_in = expire_date - datetime.utcnow()
        days_to_expire = 0
        if expire_in.days > 0:
            days_to_expire = expire_in.days

        data = {
            'domain_name': domain_info['domain'],
            'registrar': domain_info['registrar']['name'],
            'creation_date': str(notBefore),
            'expiration_date': str(expire_date),
            'days_to_expire': days_to_expire,
        }
        logging.debug('Return data:'+str(data))
        return data

    def website_get_status(self, url, search_phrase, timeout_value=15):
        logging.debug('website_get_status: url='+str(url)+", search_phrase="+search_phrase+", timeout_value="+str(timeout_value))
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.78 Safari/537.36"
        headers = {'User-Agent': user_agent}
        phrase_status = 0
        try:
            response = self.session.get(
                url, headers=headers, timeout=(timeout_value, timeout_value))
            time = round(response.elapsed.total_seconds(), 2)
            code = response.status_code
            text = response.text
            logging.debug('Text:'+str(text))
            length = len(response.content)
            speed = round(length/time)
            status = 1
            message = "''"

            if search_phrase is not None and search_phrase != '':
                if text.find(search_phrase) != -1:
                    phrase_status = 1

        except Exception as e:
            code = 0
            time = 0
            speed = 0
            status = 0
            message = e
            speed = 0
            logging.debug('Error: ' + str(e))

        data = {
            'time': time,
            'code': code,
            'status': status,
            'speed': speed,
            'phrase_status': phrase_status,
            'message': message,
        }
        return data


def output_json_lld(lld_name, objects):
    array = []
    items = {}
    for item in objects:
        items['{#'+lld_name+'}'] = item
        array.append(items)
    result = json.dumps({'data': array}, indent=4, separators=(',', ':'))
    return result


def send_data(hostname, data):
    logging.debug('Send data: ' + str(data))
    result = ''
    if hostname is not None and hostname != '':
        out = zbx_sender(hostname, data)
        result = {'zbx_sender': out}

    return result


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--discoverydomain', help='Discovery domain name from URL', type=str)

    parser.add_argument(
        '--discoveryssl', help='Discovery SSL from URL', type=str)
    
    parser.add_argument(
        '--hostname', help='Zabbix item hostname', type=str)

    parser.add_argument(
        '--testssl', help='URL for check SSL certificate', type=str)

    parser.add_argument(
        '--testdomain', help='Test domain name', type=str)

    parser.add_argument(
        '--testsite', help='Test web site', type=str)

    parser.add_argument(
        '--testphrase', help='Test web site with phrase', type=str)

    parser.add_argument(
        '--timeout', help='Timeout for web site test', type=str, default='15')

    parser.add_argument('--httpproxy',
                        help='Specify a proxy to check SSL. For example: username:password@serverfqdn:port',
                        type=str)

    parser.add_argument('--useproxy', help='Use proxy to check SSL',
                        type=str, default='False')

    parser.add_argument('--debug', help='Debug mode with verbose output',
                        type=str, default='False')

    args = parser.parse_args()

    discoverydomain = args.discoverydomain
    discoveryssl = args.discoveryssl
    test_domain = args.testdomain
    test_ssl = args.testssl
    test_site = args.testsite
    test_phrase = args.testphrase
    zbx_hostname = args.hostname
    http_proxy = args.httpproxy
    timeout = args.timeout

    if args.useproxy.lower() in ['true', '1']:
        use_proxy = True
    else:
        use_proxy = False

    if args.debug.lower() in ['true', '1']:
        logging.basicConfig(stream=sys.stderr, level=logging.DEBUG,
                            format='%(asctime)s - %(levelname)s - %(message)s')

    if http_proxy == '' and http_proxy is None:
        use_proxy = False

    logging.debug('Input arguments: ' + str(args))

    web_checks = WebSiteCheck(http_proxy, use_proxy)

    # get registred domain from URL
    if discoverydomain is not None:
        try:
            data = []
            data.append(web_checks.discovery_domain(discoverydomain))
            result = output_json_lld('WEBSITE_METRICS_LLD_DOMAIN_NAME', data)
            print(result)
            return 1
        except:
            return 0

    # discover ssl
    if discoveryssl is not None:
        try:
            url = web_checks.discovery_ssl(discoveryssl)
            data = []
            if url is not None:
                data.append(url)
            result = output_json_lld('WEBSITE_METRICS_LLD_SSL_URL', data)
            print(result)
            return 1
        except:
            return 0

    if test_domain is not None and test_domain != '':
        try:
            data = []
            domainname_result = web_checks.domain_get_status(test_domain)
            if domainname_result['days_to_expire'] > 0:
                data.append(['website_metrics.domain.status[{0}]'.format(test_domain), 1])
                data.append(['website_metrics.domain.daystoexpire[{0}]'.format(test_domain), str(
                    domainname_result['days_to_expire'])])
                data.append(['website_metrics.domain.registrar[{0}]'.format(test_domain), str(
                    domainname_result['registrar'])])
                data.append(['website_metrics.domain.creationdate[{0}]'.format(test_domain), str(
                    domainname_result['creation_date'])])
                data.append(['website_metrics.domain.expiredate[{0}]'.format(test_domain), str(
                    domainname_result['expiration_date'])])
            else:
                data.append(['website_metrics.domain.status[{0}]'.format(test_domain), 0])
            send_data(zbx_hostname, data)
            return 1
        except:
            return 0

    if test_ssl is not None and test_ssl != '':
        try:
            cert_is_valid = web_checks.ssl_verify_cert(test_ssl)
            data = []
            data.append(['website_metrics.ssl.status[{0}]'.format(test_ssl), str(cert_is_valid)])
            if cert_is_valid:
                ssl_data = web_checks.ssl_get_status(test_ssl)
                data.append(['website_metrics.ssl.daystoexpire[{0}]'.format(test_ssl),
                            str(ssl_data['days_to_expire'])])
                data.append(['website_metrics.ssl.issuedby[{0}]'.format(test_ssl),
                            str(ssl_data['issued_by'])])
                data.append(['website_metrics.ssl.issueddate[{0}]'.format(test_ssl),
                            str(ssl_data['issued_date'])])
                data.append(['website_metrics.ssl.expiredate[{0}]'.format(test_ssl),
                            str(ssl_data['expiry_date'])])
                data.append(['website_metrics.ssl.serialnumber[{0}]'.format(test_ssl),
                            str(ssl_data['serial_number'])])
            send_data(zbx_hostname, data)
            return 1
        except:
            return 0

    if test_site is not None and test_site != '':
        try:
            webtest = web_checks.website_get_status(
                test_site, test_phrase, int(timeout))
            data = []
            data.append(['website_metrics.test.status', str(webtest['status'])])
            data.append(['website_metrics.test.time', str(webtest['time'])])
            data.append(['website_metrics.test.code', str(webtest['code'])])
            data.append(['website_metrics.test.speed', str(webtest['speed'])])
            data.append(['website_metrics.test.message', str(webtest['message'])])
            data.append(['website_metrics.test.phrase_status',
                        str(webtest['phrase_status'])])
            send_data(zbx_hostname, data)
            return 1
        except:
            return 0


if __name__ == '__main__':
    main()

