#!/usr/bin/env python
import crypt
import hashlib
import sys
from random import choice

cnt = sys.argv[1]
ip = sys.argv[1]

def main(argv):
	if len(argv) == 2:
		f = open('/etc/squid/htpasswd', 'a')
		f1 = open('/etc/squid/passwd_holder', 'a')
		f2 = open('/etc/squid/users/user_' + cnt + '.conf', 'a')
		key_string = crypt.crypt("password",''.join([choice('abcdefghijklmno') for i in range(10)]))
		md5passwd = hashlib.md5( key_string ).hexdigest()
		f.write("user_" + cnt + ":" + md5passwd + '\n')
		f1.write("user_" + cnt + " / " + key_string + '\n')
		f2.write("acl net_" + cnt + " src " + ip + '\n')
		f2.write("tcp_outgoing_address " + ip + " net_" + cnt + '\n')
		f2.write("http_access allow net_" + cnt + '\n')
		f2.write("acl user_" + cnt + " proxy_auth user_" + cnt + '\n')
		f2.write("tcp_outgoing_address " + ip + " user_" + cnt + '\n')
		f2.write("http_access allow user_" + cnt + '\n')
		#print "user_", cnt, " / ",  key_string
		f.close()
		f1.close()
		f2.close()
	else:
		print "Not enough arguments"

if __name__ == "__main__":
	main(sys.argv)
