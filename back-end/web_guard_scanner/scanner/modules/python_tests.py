import subprocess
import os
import sys

def parse_xsstrike_output(output, target_url):
    found_in_url = []

    for line in output.strip().split("\n"):
        if "Vulnerable webpage" in line:
            found_in_url.append(line)
        
        if "Vector for" in line:
            print(f"PAYLOAD: {line}\n")
            
    for elem in found_in_url:
        print(f"VULNERABLE PAGES: {elem}\n")


target_url = "http://testfire.net/"

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

    parse_xsstrike_output(result.stdout, target_url)
        
except subprocess.CalledProcessError as e:
    print("--- XSStrike Failed ---")
    print("Return Code:", e.returncode)
    print("Error Output (stderr):", e.stderr) # This will tell you WHY it failed
    print("Standard Output (stdout):", e.stdout)

# except subprocess.TimeoutExpired:
#     vulnerabilities.append({
#                 'type': 'Nuclei Scan Timeout',
#                 'details': 'The Nuclei scan exceeded the 5-minute time limit.',
#                 'url_found': target_url,
#                 'severity': 'INFO'
#     })

