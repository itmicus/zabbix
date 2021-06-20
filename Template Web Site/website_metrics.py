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
import whois
from base64 import b64encode
from datetime import datetime
from dateutil import parser, relativedelta

try:
    from urllib.parse import urlparse #python3
except ImportError:
     from urlparse import urlparse #python2

__author__ = "Pavel Kuznetsov - https://itmicus.ru"
__copyright__ = "Copyright 2018, Itmicus LLC, Pavel Kuznetsov"
__license__ = "Mozilla Public License"
__version__ = "1.0"
__email__ = "p.kuznetsov@itmicus.ru"
__status__ = "Production ready"
__doc__ = """This script is part of Template_Website_metrics.xml Zabbix Monitoring template.
            It uses LLD for Domain name, SSL certificate check and website availability.

            Install: 

            1. Install requirements Python modules:
            pip install -r requirements.txt

            2. Instal whois package for you system:
            apt install whois
            yum install jwhois

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
        return domain_name.registered_domain #check main domain

    def discovery_ssl(self, url):
        o = urlparse(url)
        hostname = o.hostname
        port = 443

        if hostname is None:
            print("Check URL address, https://example.com/")
            return None

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

    def ssl_get_status(self, url, timeout_value=15):
        logging.debug('ssl_get_status:'+str(url))
        response = self.session.get(url, verify=True, timeout=(timeout_value, timeout_value), allow_redirects=False)
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

    def ssl_verify_cert(self, url, timeout_value=15):
        try:
            self.session.get(url, verify=True, timeout=(timeout_value, timeout_value), allow_redirects=False)
            logging.debug('ssl_verify_cert: OK')
            return 1
        except Exception as e:
            logging.debug('Error: ' + str(e))
            return 0

    def domain_get_status(self, domain):
        domain_name = tldextract.extract(domain)
        domain = domain_name.registered_domain
        domain = whois.query(domain)

        logging.debug('Domain check result ' + str(domain.__dict__))

        expire_in = domain.expiration_date.replace(tzinfo=None) - datetime.utcnow().replace(tzinfo=None)
        days_to_expire = 0
        if expire_in.days > 0:
            days_to_expire = expire_in.days

        data = {
            'domain_name': domain.name,
            'registrar': domain.registrar,
            'creation_date': domain.creation_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
            'expiration_date': domain.expiration_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
            'days_to_expire': days_to_expire,
        }
        logging.debug('Return data:'+str(data))
        return data

    def website_get_status(self, url, search_phrase, timeout_value=15):
        logging.debug('website_get_status: url='+str(url)+", search_phrase="+str(search_phrase)+", timeout_value="+str(timeout_value))
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.78 Safari/537.36"
        headers = {'User-Agent': user_agent}
        phrase_status = 0
        if int(timeout_value) > 20:
            timeout_value = 20
        try:
            response = self.session.get(
                url, headers=headers, timeout=(int(timeout_value), int(timeout_value)))
            time = round(response.elapsed.total_seconds(), 2)
            code = response.status_code

            if isinstance(response.text, str): #if python3, it's already in unicode
                text = response.text
            else:
                text = response.text.encode('utf8') # encode, if python2

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
            message = 'Error: ' + str(e)
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

def main():
    parser = argparse.ArgumentParser(description='Website metrics script helps to parse, checks SSL certs and website.')

    parser.add_argument(
        '--discoverydomain', help='Discovery domain name from URL', type=str)

    parser.add_argument(
        '--discoveryssl', help='Discovery SSL from URL', type=str)
    
    parser.add_argument(
        '--testssl', help='URL for check SSL certificate', type=str)

    parser.add_argument(
        '--testdomain', help='Test domain name', type=str)

    parser.add_argument(
        '--testsite', help='Test web site', type=str)

    parser.add_argument(
        '--testphrase', help='Test web site with phrase', type=str)

    parser.add_argument(
        '--timeout', help='Timeout for web site test, sec', type=str, default='15')

    parser.add_argument('--httpproxy',
                        help='Specify a proxy to check SSL. For example: username:password@serverfqdn:port',
                        type=str)

    parser.add_argument('--useproxy', help='Use proxy to check SSL',
                        type=str, default='False')

    parser.add_argument('--debug', help='Debug mode with verbose output',
                        type=str, default='False')
    
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')

    args = parser.parse_args()

    discoverydomain = args.discoverydomain
    discoveryssl = args.discoveryssl
    test_domain = args.testdomain
    test_ssl = args.testssl
    test_site = args.testsite
    test_phrase = args.testphrase
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

    # Discovery block
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
    # Discovery block end

    # return JSON for Domain items prototype
    if test_domain is not None and test_domain != '':
        try:
            data = dict()
            domainname_result = web_checks.domain_get_status(test_domain)
            if domainname_result['days_to_expire'] > 0:
                data.update({'domain_status': 1})
                data.update({'domain_daystoexpire': domainname_result['days_to_expire']})
                data.update({'domain_registrar': domainname_result['registrar']})
                data.update({'domain_creationdate': domainname_result['creation_date']})
                data.update({'domain_expiredate': domainname_result['expiration_date']})
            else:
                data.update({'domain_status': 0})
            json.dump(data, sys.stdout)
            return 1
        except:
            return 0

    # return JSON for SSL items prototype
    if test_ssl is not None and test_ssl != '':
        try:
            cert_is_valid = web_checks.ssl_verify_cert(test_ssl)
            data = {
                'ssl_status' : cert_is_valid
            }
            if cert_is_valid:
                ssl_data = web_checks.ssl_get_status(test_ssl)
                data.update({'ssl_daystoexpire': ssl_data['days_to_expire']})
                data.update({'ssl_issuedby': ssl_data['issued_by']})
                data.update({'ssl_expiredate': ssl_data['expiry_date'].strftime("%c")})
                data.update({'ssl_issueddate': ssl_data['issued_date'].strftime("%c")})
                data.update({'ssl_serialnumber': ssl_data['serial_number']})
            json.dump(data, sys.stdout)
            return 1
        except:
            return 0

    if test_site is not None and test_site != '':
        try:
            webtest = web_checks.website_get_status(test_site, test_phrase, timeout)
            data = {'test_status': webtest['status']}
            data.update({'test_time': webtest['time']})
            data.update({'test_code': webtest['code']})
            data.update({'test_speed': webtest['speed']})
            data.update({'test_message': webtest['message']})
            data.update({'test_phrase_status': webtest['phrase_status']})
            json.dump(data, sys.stdout)
            return 1
        except:
            return 0
    
    # print help message if no args passed
    if len(sys.argv)==1:
        parser.print_help(sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

