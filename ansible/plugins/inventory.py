#!/usr/bin/python

import urllib
import json
from optparse import OptionParser

p = OptionParser()
p.add_option('-l', '--list', dest='list', action="store_true")
p.add_option('-s', '--host', dest='host', default=False)

(options, args) = p.parse_args()

staticHosts = {
}

url = urllib.urlopen("https://example.com/api/ansible.php?key=KEY_INPUT=getallansible")
data = url.read().rstrip()

hostMap = {}
for x in data.split("\n"):
	ip, hostname = x.split(":")
	hostMap[ip] = { 'hostname' : hostname }

if options.list:
	grouped = { }
	for ip in staticHosts.keys():
		for group in staticHosts[ip]['groups']:
			if group not in grouped:
				grouped[group] = { 'hosts' : []}
			grouped[group]['hosts'].append(ip)
	grouped['servers'] = { 'hosts' : hostMap.keys() }

	print(json.dumps(grouped, ensure_ascii=True))
elif options.host:
	if options.host in staticHosts:
		print(json.dumps(staticHosts[options.host]))
	elif options.host in hostMap:
		print(json.dumps(hostMap[options.host]))
	else:
		print('[]')
