from web_guard_scanner.models import Scan, Vulnerability

from .modules.ffuf_scanner_module import FuzzScannerModule
from .modules.sqlmap_scanner_module import SqlmapScannerModule
from .modules.xsstrike_crawler_module import XsstrikeCrawlerModule
from .modules.xsstrike_scanner_module import XsstrikeScannerModule
from .modules.wafwoof_detection_module import WafwoofDetectionModule
from .modules.nmap_version_detection_module import NmapVersionDetectionModule

from .crawler import ReconCrawler

from django.utils import timezone
from datetime import date

from urllib.parse import urlparse

scanning_modules_dictionary = {
            'sqli' : SqlmapScannerModule,
            'xss-crawler' : XsstrikeCrawlerModule,
            'xss-scanner' : XsstrikeScannerModule,
            'fuzz' : FuzzScannerModule, 
}

class ScanManager:

    def __init__(self, scan_id):
        self.scan = Scan.objects.get(id= scan_id)
        self.target_url = self.scan.target.url
        self.modules_to_run = self.scan.modules_selected

    def run_scan(self):
        self.scan.status = 'RUNNING'
        self.scan.start_time = timezone.now()
        self.scan.date = date.today()
        self.scan.save()

        all_findings = []
        urls_to_scan = [self.target_url]
        
        #if self.scan.target.owner.profile.user_type == 'PRO':
        if "recon-crawler" in self.modules_to_run:
            parameter_crawler = ReconCrawler(self.target_url)
            crawled_urls = parameter_crawler.crawl()

            if crawled_urls:
                urls_to_scan.extend(crawled_urls)

        if 'waf-detection' in self.modules_to_run:
            waf_detection_module = WafwoofDetectionModule()
            findings = waf_detection_module.scan(self.target_url)
            if findings:
                all_findings.append(findings)

        if 'services-detection' in self.modules_to_run:
            parsed = urlparse(self.target_url)
            domain = parsed.netloc if parsed.netloc else parsed.path.split('/')[0]
            version_detection_module = NmapVersionDetectionModule()
            findings = version_detection_module.scan(domain)
            if findings:
                all_findings.append(findings)

        scanner_names = [scanner for scanner in self.modules_to_run if scanner in scanning_modules_dictionary]

        for url in urls_to_scan:
            for module_name in scanner_names:
                module_class = scanning_modules_dictionary[module_name]
                module_instance = module_class()

                findings = module_instance.scan(url)
                if findings:
                    all_findings.append(findings)

        findings_list = []
        for finding in all_findings:
            elements = finding if isinstance(finding, list) else [finding]
            findings_list.extend(elements)

        self.save_vulnerabilities(findings_list)
        
        base_score = 100
        for finding in findings_list:
            severity = finding.get('severity', 'INFO').upper() 

            if severity == 'CRITICAL':
                base_score -= 50
            elif severity == 'HIGH':
                base_score -= 30
            elif severity == 'INFO':
                base_score -= 5
            elif severity == 'MEDIUM':
                base_score -= 15
            elif severity == 'ERROR':
                base_score -= 100

        self.scan.score = max(0, base_score)
        self.scan.status = 'COMPLETED'
        self.scan.end_time = timezone.now()
        self.scan.save()

    def save_vulnerabilities(self, vulnerabilities):
        to_create = []
        
        for vulnerability in vulnerabilities:
            to_create.append(Vulnerability(scan=self.scan, **vulnerability))
        
        Vulnerability.objects.bulk_create(to_create)
