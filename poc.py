import requests
url= 'https://raw.githubusercontent.com/void010/dummy/main/dummy.txt'
r = requests.get(url, allow_redirects=True)
open('dummy.txt', 'wb').write(r.content)
