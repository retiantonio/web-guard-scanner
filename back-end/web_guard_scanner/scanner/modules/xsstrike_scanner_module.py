from .abstract_scanner_module import AbstractScannerModule

import sys
import os
import subprocess


class XsstrikeScannerModule(AbstractScannerModule): #detect XSS - extremely effective

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
        
        except subprocess.CalledProcessError as e:
            print("--- XSStrike Failed ---")
            print("Return Code:", e.returncode)
            print("Error Output (stderr):", e.stderr)
            print("Standard Output (stdout):", e.stdout)

    def parse_xsstrike_output(self, output, target_url):
        
        vulnerability = {
            "type": "Cross-Site Scripting",
            "details": "No details given",
            "url_found": target_url,
            "severity": "HIGH"
        }

        payloads = []
        found_in_url = []
        for line in output.strip().split("\n"):
            if "Vulnerable webpage" in line:
                found_in_url.append(line)
            elif "Vector for" in line:
                payloads.append(line)
        
        if len(payloads) > 0:
            description = "XSS payloads found:\n"
            for payload in payloads: #No payloads => TO BE CHANGED SO FAR ITS NO RISKS
                description += f"{payload}\n"
        else:
            return None
        
        vulnerability["details"] = description

        return vulnerability

