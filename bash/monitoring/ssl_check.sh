#! /bin/sh
FILE=$1
RETVAL=0
TIMESTAMP=50


while read DOMAINNAME; do

EXPIRE_DATE=`echo | openssl s_client -showcerts -servername $DOMAINNAME -connect $DOMAINNAME:443 2>/dev/null | openssl x509 -inform pem -noout -text| grep 'Not After' | sed 's|.*After : ||'`


EXPIRE_SECS=`TZ=GMT date -d "${EXPIRE_DATE}" +%s`
EXPIRE_TIME=$(( ${EXPIRE_SECS} - `TZ=GMT date +%s` ))

if test $EXPIRE_TIME -lt 0
	then
	RETVAL=0
	else
	RETVAL=$(( ${EXPIRE_TIME} / 24 / 3600 ))
fi

#sleep 5

expired () {

if [ "$RETVAL" -le "$TIMESTAMP" ]; then 
	echo "$DOMAINNAME  will expire soon"
else 
	continue
fi
}


#echo $EXPIRE_DATE
done < $FILE

#echo ${RETVAL}
