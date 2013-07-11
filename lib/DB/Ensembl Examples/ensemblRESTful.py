import httplib2, sys
import pprint
http = httplib2.Http(".cache")

server = "http://beta.rest.ensembl.org"

ext = "/vep/mouse/id/rs31701671/consequences?"
resp, content = http.request(server+ext, method="GET", headers={"Content-Type":"application/json"})
 
if not resp.status == 200:
  print "Invalid response: ", resp.status
  sys.exit()
import json
 
decoded = json.loads(content)
pprint.pprint(decoded['data'][0])