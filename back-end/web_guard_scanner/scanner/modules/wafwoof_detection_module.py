from .abstract_scanner_module import AbstractScannerModule

import subprocess
import json

class WafwoofDetectionModule(AbstractScannerModule):

    def scan(self, target_url):
        command = ['wafw00f', target_url, '-f', 'json', '-o', '-']
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=30)
            if not result or not result.stdout: return self.return_error_output(target_url, 
                                                            "Error! wafw00f encountered an error, make sure the URL is valid.")
            
            if "appears to be down" in result.stderr or "NameResolutionError" in result.stderr:
                return self.return_error_output(target_url, 
                            "Error! wafw00f encountered an error, make sure the URL is valid.")
            
            json_formatted_result = json.loads(result.stdout)
            if not json_formatted_result: return self.return_error_output(target_url, 
                                                    "Error! wafw00f encountered an error, make sure the URL is valid.")

            return {
                "type": "Web Application Firewall Detection (WAF)",
                "url_found": target_url,
                "severity": "INFO",
                "details": {
                    "findings": json_formatted_result
                }
            }

        except subprocess.TimeoutExpired:
            return self.return_error_output(target_url, 
                        "Error! wafw00f timed out.")
        
        except subprocess.CalledProcessError:
            return self.return_error_output(target_url, 
                        "Error! wafw00f process error.")

    def return_error_output(self, target_url, message):
        error_found = {
            "type": "Web Application Firewall Detection (WAF)",
            "url_found": target_url,
            "severity": "ERROR",
            "details": {
                "message": [
                    message
                ]
            }
        }
                    
        return error_found
