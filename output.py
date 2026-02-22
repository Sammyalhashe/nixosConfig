import sys
import os
import logging
from typing import List
from dataclasses import dataclass, field
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

# Add parent directory to path for imports when running as module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.settings import BASE_URL, DEFAULT_HEADERS, REQUEST_TIMEOUT, MAX_RETRIES, TOP_N
from utils.logger import log_info, log_error
from scraper.models import Repository


class NetworkError(Exception):
    """Custom exception for network-related errors."""
    pass


class ParsingError(Exception):
    """Custom exception for HTML parsing errors."""
    pass


class GitHubTrendingClient:
    def __init__(self, base_url: str = BASE_URL, headers: dict = DEFAULT_HEADERS,
                 timeout: int = REQUEST_TIMEOUT, max_retries: int = MAX_RETRIES):
        self.base_url = base_url
        self.headers = headers
        self.timeout = timeout
        self.max_retries = max_retries

    def fetch_page(self) -> str:
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                response = requests.get(
                    self.base_url,
                    headers=self.headers,
                    timeout=self.timeout
                )
                if response.status_code == 200:
                    return response.text
                else:
                    last_exception = NetworkError(f"HTTP {response.status_code}")
            except requests.RequestException as e:
                last_exception = e

            # Exponential backoff
            if attempt < self.max_retries - 1:
                import time
                time.sleep(2 ** attempt)

        raise NetworkError(f"Failed to retrieve page after {self.max_retries} attempts: {last_exception}")


class TrendingParser:
    def __init__(self, html: str):
        self.html = html

    def parse(self) -> List[Repository]:
        try:
            soup = BeautifulSoup(self.html, "html.parser")
            articles = soup.select("article.Box-row")
            
            if not articles:
                raise ParsingError("No repository entries found in the trending page")
            
            repositories = []
            for article in articles[:TOP_N]:
                h1 = article.find("h1")
                if not h1:
                    raise ParsingError("Expected <h1> element not found in repository entry")
                
                text = h1.get_text(strip=True)
                parts = text.split("/")
                if len(parts) != 2:
                    raise ParsingError(f"Invalid repository format: '{text}'")
                
                owner, name = [part.strip() for part in parts]
                repo_url = urljoin("https://github.com/", f"{owner}/{name}")
                repositories.append(Repository(owner=owner, name=name, url=repo_url))
            
            return repositories
        except Exception as e:
            if isinstance(e, (NetworkError, ParsingError)):
                raise
            raise ParsingError(f"Error parsing HTML: {str(e)}")


def main():
    try:
        client = GitHubTrendingClient()
        html = client.fetch_page()
        
        parser = TrendingParser(html)
        repositories = parser.parse()
        
        for repo in repositories[:TOP_N]:
            log_info(repo.full_name)
            
    except NetworkError as e:
        log_error(f"Network error: {e}")
        sys.exit(1)
    except ParsingError as e:
        log_error(f"Parsing error: {e}")
        sys.exit(1)
    except Exception as e:
        log_error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()