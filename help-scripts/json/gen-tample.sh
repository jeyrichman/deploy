#!/bin/bash

while read -r i;do \
HOSTNAME=`echo $i | awk '{print $1}'`
IP=`echo $i | awk '{print $2}'`
DOMAIN=`echo $i | awk '{print $3}'`

cat <<EOF >> out.txt
                "$HOSTNAME" : {
			"ip" : "$IP",
			"domains" : { 
			"$DOMAIN" : {
				"le-ssl" : [ "www" ],
				"ssl_disabled" : "true",
				"force_ssl" : "false"
				}				
			}
		},
EOF
done < list
