from .abstract_scanner_module import AbstractScannerModule

import sys
import os
import subprocess
import re

class XsstrikeScannerModule(AbstractScannerModule): #detect XSS - extremely effective

    def scan(self, target_url):

        xsstrike_dir = '/home/kali/XSStrike/'
        script_path = os.path.join(xsstrike_dir, 'xsstrike.py')

        command = [
                sys.executable,
                script_path,
                '--url', target_url, #must be parametrized url
        ]

        try:
            result = subprocess.run(
                    command,
                    capture_output=True, 
                    text=True, 
                    timeout=30,
                    check=True,
                    cwd=xsstrike_dir 
            )

            return self.parse_xsstrike_output(result.stdout, target_url)
        
        except subprocess.TimeoutExpired as e:
            print(f"Process timed out! Captured output so far...")
            
            raw_output = e.stdout.decode('utf-8') if isinstance(e.stdout, bytes) else e.stdout
            if raw_output:
                return self.parse_xsstrike_output(raw_output, target_url)
            return None
        
        except subprocess.CalledProcessError as e:
            print("XSStrike failed")

    def parse_xsstrike_output(self, output, target_url):
        if not output or "[-]" in output:
            print("[-] XSStrike error or no output\n")
            return None
        
        pattern = r"(?:Reflections found):\s+(.*)"
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')

        for line in output.strip().split("\n"):
            match = re.search(pattern, line)
            if match:

                raw_count = match.group(1).strip()
                clean_count = ansi_escape.sub('', raw_count)

                vulnerability = {
                    "type": "Cross-Site Scripting (XSS)",
                    "url_found": target_url,
                    "severity": "HIGH",
                    "details": {
                        "findings": [
                            {
                                "description": "Reflection found",
                                "reflection_count": clean_count
                            }
                        ]
                    }
                }
                
                return vulnerability
                
        return None