from web_guard_scanner.models import Scan, Vulnerability

from .modules.ffuf_scanner_module import FuzzScannerModule
from .modules.sqlmap_scanner_module import SqlmapScannerModule
from .modules.xsstrike_crawler_module import XsstrikeCrawlerModule
from .modules.xsstrike_scanner_module import XsstrikeScannerModule
from .modules.wafwoof_detection_module import WafwoofDetectionModule
from .modules.nmap_version_detection_module import NmapVersionDetectionModule

from .crawler import ReconCrawler

scanning_modules_dictionary = {
            'sqli' : SqlmapScannerModule,
            'xss-crawler' : XsstrikeCrawlerModule,
            'xss-scanner' : XsstrikeScannerModule,
            'fuzz' : FuzzScannerModule, 
            'waf-detection' : WafwoofDetectionModule,
            'services-detection' : NmapVersionDetectionModule
}

class ScanManager:

    def __init__(self, scan_id):
        self.scan = Scan.objects.get(id= scan_id)
        self.target_url = self.scan.target.url
        self.modules_to_run = self.scan.modules_selected

    def run_scan(self):
        self.scan.status = 'RUNNING'

        all_findings = []
        urls_to_scan = [self.target_url]

        if "recon-crawler" in self.modules_to_run:
            parameter_crawler = ReconCrawler(self.target_url)
            crawled_urls = parameter_crawler.crawl()

            if crawled_urls:
                urls_to_scan.extend(crawled_urls)

        scanner_names = [scanner for scanner in self.modules_to_run if scanner in scanning_modules_dictionary]

        for url in urls_to_scan:
            for module_name in scanner_names:
                module_class = scanning_modules_dictionary[module_name]
                module_instance = module_class()

                findings = module_instance.scan(url)
                if findings:
                    all_findings.append(findings)


        self.save_vulnerabilities(all_findings)
        self.scan.status = 'COMPLETED'
        self.scan.save()

    def save_vulnerabilities(self, vulnerabilities):
        to_create = []
        
        for item in vulnerabilities:
            elements = item if isinstance(item, list) else [item]
            for data in elements:
                to_create.append(Vulnerability(scan=self.scan, **data))
        
        Vulnerability.objects.bulk_create(to_create)
