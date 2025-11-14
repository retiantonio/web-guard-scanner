from .abstract_scanner_module import AbstractScannerModule

class FuzzScannerModule(AbstractScannerModule):   # Brute-force the parametrized urls for 
                                                  # potential sqli or xss using a good wordlist from github
    def scan(self, target_url):
        pass
