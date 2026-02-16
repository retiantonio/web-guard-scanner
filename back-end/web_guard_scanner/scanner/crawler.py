import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse, parse_qs

class ReconCrawler:
    def __init__(self, base_url):
        self.base_url = base_url
        self.domain = urlparse(base_url).netloc

        self.seen_fingerprints = set()
        self.visited = set()
        self.parametrized = []

    def get_fingerprint(self, url):
        parsed = urlparse(url)
        path = parsed.path
        params = sorted(parse_qs(parsed.query).keys()) 
        return f"{path}|{','.join(params)}"


    def crawl(self, url = None):
        if url is None: url = self.base_url
        if url in self.visited or self.domain not in url:
            return
        
        self.visited.add(url)

        if '?' in url:
            fingerprint = self.get_fingerprint(url)
            print(f"[/] Finger Print: {fingerprint}\n")
            if fingerprint not in self.seen_fingerprints:
                self.seen_fingerprints.add(fingerprint)
                self.parametrized.append(url)
                print(f"[+] Found unique target: {url}")

        try:
            response = requests.get(url, timeout = 5)
            soup = BeautifulSoup(response.text, 'html.parser')

            for link in soup.find_all('a', href = True):
                full_url = urljoin(self.base_url, link['href'])

                if self.domain in full_url:
                    self.crawl(full_url)

        except Exception as e:
            print(f"Error crawling {url}: {e}")

        return list(self.parametrized)

        



        




    
