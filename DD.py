#import libraries
import sys
import requests
import bs4



def get_raw_resp(url):
    """Get webpage response as a unicode string."""
    try:
        headers = {"User-Agent": random.choice(USER_AGENTS)}
        try:
            request = requests.get(url, headers=headers, proxies=get_proxies())
        except MissingSchema:
            url = add_protocol(url)
            request = requests.get(url, headers=headers, proxies=get_proxies())
        return request.text.encode("utf-8") if PY2 else request.text
    except Exception:
        sys.stderr.write("Failed to retrieve {0} as str.\n".format(url))
        raise

def add_protocol(url):
    """Add protocol to URL."""
    if not check_protocol(url):
        return "http://{0}".format(url)
    return url


def check_protocol(url):
    """Check URL for a protocol."""
    if url and (url.startswith("http://") or url.startswith("https://")):
        return True
    return False


def remove_protocol(url):
    """Remove protocol from URL."""
    if check_protocol(url):
        return url.replace("http://", "").replace("https://", "")
    return url


def clean_url(url, base_url=None):
    """Add base netloc and path to internal URLs and remove www, fragments."""
    parsed_url = urlparse(url)

    fragment = "{url.fragment}".format(url=parsed_url)
    if fragment:
        url = url.split(fragment)[0]

    # Identify internal URLs and fix their format
    netloc = "{url.netloc}".format(url=parsed_url)
    if base_url is not None and not netloc:
        parsed_base = urlparse(base_url)
        split_base = "{url.scheme}://{url.netloc}{url.path}/".format(url=parsed_base)
        url = urljoin(split_base, url)
        netloc = "{url.netloc}".format(url=urlparse(url))

    if "www." in netloc:
        url = url.replace(netloc, netloc.replace("www.", ""))
    return url.rstrip(string.punctuation)

if len(sys.argv) == 3:
	#If arguments are satisfied store them in readable variables

	url = 'http://%s' % sys.argv[1]
	file_name = sys.argv[2]

	print('Grabbing the page...')
	#Get url from command line
	response = requests.get(url)
	page = requests.get(url)
	response.raise_for_status()

	#Retrieving all links on the page
	#soup = bs4.BeautifulSoup(response.text, 'html.parser')

	soup = bs4.BeautifulSoup(page.content, 'html.parser')
	links = soup.find_all('a')

	content = soup.find('div', {"class": "story-body sp-story-body gel-body-copy"})
	#content = soup.find(div_id="wrapper")
	article = ''
	for i in content.findAll('p'):
		article = article + ' ' +  i.text

	print(article)

# Saving the scraped text
	with open('scraped_text.txt', 'w') as file:
		file.write(article)

	file = open(file_name, 'wb')
	print('Collecting the links...')
	for link in links:
		href = link.get('href') + '\n'
    	file.write(href.encode())
	file.close()
	print('Saved to %s' % file_name)

else:
	print('Usage: ./DD.py wwww.example.com file.txt')
