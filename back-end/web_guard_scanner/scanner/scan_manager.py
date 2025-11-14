from models import Scan, Vulnerability

from .modules.ffuf_scanner_module import FuzzScannerModule
from .modules.sqlmap_scanner_module import SqlmapScannerModule
from .modules.xsstrike_scanner_module import XsstrikeScannerModule

modules_dictionary = {
            'sqli' : SqlmapScannerModule,
            'xss' : XsstrikeScannerModule,
            'fuzz' : FuzzScannerModule, 
            # To be extended
}

class ScanManager: # Scan Manager Scheleton so far

    def __init__(self, scan_id):
        self.scan = Scan.objects.get(id= scan_id)
        self.target_url = self.scan.target
        self.modules_to_run = self.scan.modules_selected

    def run_scan(self):
        self.scan.status = 'RUNNING'

        all_findings = []

        for module_name in self.modules_to_run:
            if module_name in modules_dictionary:
                module_class = modules_dictionary[module_name]
                module_instance = module_class()

                findings = module_instance.scan(self.target_url)
                all_findings.extend(findings)

        self.save_vulnerabilities(all_findings)
        self.scan.status = 'COMPLETED'
        self.scan.save()


    def save_vulnerabilities(self, vulnerabilities):
        for vulnerability in vulnerabilities:
            Vulnerability.objects.create(
                scan = self.scan,
                type = vulnerability['type'],
                details = vulnerability['details'],
                url_found = vulnerability['url_found'],
                severity = vulnerability['severity']
            )
