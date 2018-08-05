import unittest
from ddt import ddt, data, unpack
from website_metrics import WebSiteCheck

"""
Unit tests for website_metrics.py

Before run, please install:
pip install ddt

"""

@ddt
class Test_website_metrics(unittest.TestCase):
    def setUp(self):
        self.web_checks = WebSiteCheck("", "")

    def test_one(self):
        result = 1
        self.assertEqual(1, result)

    @unpack
    @data({'url': 'https://gmail.com:4444/dsaq?wer=34&wer', 'domain': 'gmail.com'},
          {'url': 'http://facebook.com', 'domain': 'facebook.com'},
          {'url': 'http://yandex.ru', 'domain': 'yandex.ru'},
          )
    def test_discovery_domain(self, url, domain):
        result = self.web_checks.discovery_domain(url)
        self.assertEqual(domain, result)

    @unpack
    @data({'url': 'https://gmail.com:', 'ssl_url': 'https://gmail.com:443'},
          {'url': 'http://facebook.com', 'ssl_url': 'https://facebook.com:443'},
          {'url': 'http://yandex.ru/', 'ssl_url': 'https://yandex.ru:443'}
          )
    def test_discovery_ssl(self, url, ssl_url):
        result = self.web_checks.discovery_ssl(url)
        self.assertEqual(ssl_url, result)

    # def test_domain_name(self):
    #     domain_name_result = self.web_checks.domain_get_status("gmail.com")
    #     self.assertEqual("MarkMonitor, Inc.", domain_name_result['registrar'])

    @data("https://gmail.com:443", "https://yandex.ru:443", "https://youtube.com:443", "https://facebook.com:443")
    def test_ssl_certificate_status(self, value):
        ssl_result = self.web_checks.ssl_verify_cert(value)
        self.assertEqual(1, ssl_result)

    @data("https://gmail.com:443", "https://yandex.ru:443", "https://youtube.com:443", "https://facebook.com:443")
    def test_ssl_certificate(self, value):
        ssl_result = self.web_checks.ssl_get_status(value)
        days_to_expire = ssl_result['days_to_expire']
        self.assertGreater(days_to_expire, 1)

    @data("https://gmail.com:443", "https://yandex.ru:443", "https://youtube.com:443", "https://facebook.com:443", "http://bus.gov.ru", "http://www.zoovet.ru")
    def test_web_site_status(self, value):
        web_site_status = self.web_checks.website_get_status(
            value, "")
        self.assertEqual(1, web_site_status['status'])

    @data("https://gmail.com:443", "http://yandex.ru", "https://youtube.com:443", "https://facebook.com:443", "http://bus.gov.ru", "http://www.zoovet.ru")
    def test_web_site_code(self, value):
        web_site_status = self.web_checks.website_get_status(
            value, "")
        self.assertEqual(200, web_site_status['code'])

    @unpack
    @data({'url': 'https://gmail.com:443', 'phrase': 'Gmail'},
          {'url': 'https://facebook.com:443', 'phrase': 'Account'},
          {'url': 'https://www.lanit.ru', 'phrase': 'Мурманский проезд, д. 1'},
          {'url': 'http://bus.gov.ru/', 'phrase': 'Казначейство'})
    def test_web_site_phrase(self, url, phrase):
        web_site_status = self.web_checks.website_get_status(url, phrase)
        self.assertEqual(1, web_site_status['phrase_status'])

    @unpack
    @data({'url': 'https://gmail.com:443', 'phrase': 'Yandex'},
          {'url': 'https://facebook.com:443', 'phrase': 'Blablabla'})
    def test_web_site_phrase_notfound(self, url, phrase):
        web_site_status = self.web_checks.website_get_status(url, phrase)
        self.assertEqual(0, web_site_status['phrase_status'])

    @unpack
    @data({'url': 'https://gmail.com:443', 'timeout': 1},
          {'url': 'https://facebook.com:443', 'timeout': 3},
          {'url': 'http://bus.gov.ru/', 'timeout': 0.1})
    def test_web_site_timeout(self, url, timeout):
        web_site_status = self.web_checks.website_get_status(url, "", timeout)
        self.assertEqual(200, web_site_status['code'])
