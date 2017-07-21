DOMAIN=`pwd | cut -d "/" -f 5 | sed 's/\./\-/g'`
DB_USER=`cat wp-config.php | grep "DB_USER"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
DB_PASSWORD=`cat wp-config.php | grep "DB_PASSWORD"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
DB_HOST=`cat wp-config.php | grep "DB_HOST"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
sleep 2
sed -i "s/$DB_HOST/localhost/" wp-config.php
sed -i "s/$DB_USER/root/" wp-config.php
sed -i "s/$DB_PASSWORD/123123asd/" wp-config.php

/usr/bin/mysql < $DOMAIN.sql
rm -rf 
