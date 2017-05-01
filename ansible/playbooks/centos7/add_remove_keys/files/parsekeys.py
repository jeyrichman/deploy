#!/usr/bin/env python
import os
import re
import urllib
keys = urllib.URLopener()
keys.retrieve("http://example.com/authorized_keys", "/root/.ssh/keys/authorized_keys")

with open("/root/.ssh/keys/authorized_keys", "r") as f:
	        i = 1
	        for line_1 in f:
	                with open("/root/.ssh/keys/user_key." + str(i) + ".pub", "a") as fw:
                                fw.write(line_1)
                                i = i +1
                                fw.close()
                                with open("/root/.ssh/authorized_keys", "r+") as key:
                                        line_found = any(line_1 in line for line in key)
                                        if not line_found:
                                               key.seek(0, os.SEEK_END)
                                               key.write(line_1)
                                               key.close()
