from abc import ABC, abstractmethod

class AbstractScannerModule(ABC): # Base of all the scanning modules

    @abstractmethod
    def scan(self, target_url):
        # Every module has its own scanner
        pass