from .abstract_scanner_module import AbstractScannerModule

import sys
import os
import subprocess
import re

class XsstrikeCrawlerModule(AbstractScannerModule): #detect XSS - extremely effective

    def scan(self, target_url):

        xsstrike_dir = '/home/kali/XSStrike/'
        script_path = os.path.join(xsstrike_dir, 'xsstrike.py')

        command = [
                sys.executable,
                script_path,
                '--url', target_url,
                '--crawl',
        ]

        try:
            result = subprocess.run(
                    command,
                    capture_output=True, 
                    text=True, 
                    timeout=300,
                    check=True,
                    cwd=xsstrike_dir 
            )

            return self.parse_xsstrike_output(result.stdout, target_url)
        
        except subprocess.CalledProcessError:
           return self.return_error_output(target_url, 
                        "Error! XSStrike process error.")
        except subprocess.TimeoutExpired:
            return self.return_error_output(target_url, 
                        "Error! XSStrike timed out.")


    def parse_xsstrike_output(self, output, target_url):
        if not output or "[-]" in output:
            print("[-] XSStrike error or no output\n")
            return self.return_error_output(target_url, 
                        "Error! XSStrike encountered an error.")
        

        findings = []

        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        clean_output = ansi_escape.sub('', output)

        pattern = r"\[\+\+\] Vulnerable webpage:\s*(.*?)\n\[\+\+\] Vector for (.*?):\s*(.*?)(?:\n|$)"
        
        matches = re.findall(pattern, clean_output, re.MULTILINE)
        
        for url, parameter, vector in matches:
            findings.append({
                "type": "Cross-Site Scripting (XSS)",
                "url_found": url.strip(),
                "details": {
                    "findings": [
                        {
                            "parameter": parameter.strip(),
                            "payload": vector.strip(),
                            "description": "Reflected XSS detected"
                        }
                    ]
                },
                "severity": "HIGH"
            })
        
        return findings

    def return_error_output(self, target_url, message):
        error_found = {
                        "type": "Cross-Site Scripting (XSS)",
                        "url_found": target_url,
                        "severity": "ERROR",
                        "details": {
                            "message": [
                                message
                            ]
                        }
        }
                    
        return error_found