import urllib.request
from urllib.error import HTTPError

try:
    response = urllib.request.urlopen('https://upgrade.trogon.info/api/exam/access?exam_id=387')
    print(response.read().decode('utf-8'))
except HTTPError as e:
    print(e.read().decode('utf-8'))
