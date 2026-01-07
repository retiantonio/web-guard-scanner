from .abstract_scanner_module import AbstractScannerModule

import subprocess
import json

class WafwoofDetectionModule(AbstractScannerModule):

    def scan(self, target_url):
        command = ['wafw00f', target_url, '-f', 'json', '-o', '-']
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=30)
            if not result: return None

            json_formatted_result = json.loads(result.stdout)
            if json_formatted_result:
                return {
                    "type": "Web Application Firewall Detection (WAF)",
                    "url_found": target_url,
                    "severity": "INFO",
                    "details": {
                        "findings": json_formatted_result
                    }
                }

        except subprocess.TimeoutExpired:
            return None
        
        except subprocess.CalledProcessError:
            return None


