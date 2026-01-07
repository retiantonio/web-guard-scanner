from .abstract_scanner_module import AbstractScannerModule

import subprocess
import json
import xml.etree.ElementTree as ET

from urllib.parse import urlparse

class NmapVersionDetectionModule(AbstractScannerModule):

    def scan(self, target_url):
        parsed = urlparse(target_url)
        domain = parsed.netloc if parsed.netloc else parsed.path.split('/')[0]
        
        home_dir = '/home/kali/'

        #nmap -sV -oX - testphp.vulnweb.com
        command = ['nmap', '-sV', '-oX', '-', domain]
        try:
            result = subprocess.run(
                    command,
                    capture_output=True, 
                    text=True, 
                    timeout=300,
                    check=True,
                    cwd = home_dir
            )

            return self.parse_nmap_xml(result.stdout, target_url)
        
        except subprocess.TimeoutExpired:
            return None
        except subprocess.CalledProcessError:
            return None 

    def parse_nmap_xml(self, xml_string, target_url):
        root = ET.fromstring(xml_string)
        scan_results = []

        for host in root.findall('host'):
            for port in host.find('ports').findall('port'):
                service = port.find('service')
                
                findings = {
                    "port": port.get('portid'),
                    "protocol": port.get('protocol'),
                    "state": port.find('state').get('state'),
                    "service_name": service.get('name') if service is not None else "unknown",
                    "product": service.get('product') if service is not None else "unknown",
                    "version": service.get('version') if service is not None else "unknown",
                }
                scan_results.append(findings)

        vulnerability = {
                "type": "Service Discovery (NMAP)",
                "url_found": target_url,
                "severity": "INFO",
                "details": {
                    "findings": scan_results
                }
            }

        return vulnerability