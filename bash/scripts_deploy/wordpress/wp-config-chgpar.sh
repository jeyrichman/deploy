cd /var/www/html/*
DB_USER=`cat wp-config.php | grep "DB_USER"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
/bin/sed -i "s/$DB_USER/root/" wp-config.php
DB_PASSWORD=`cat wp-config.php | grep "DB_PASSWORD"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
/bin/sed -i "s/$DB_PASSWORD/123123asd/" wp-config.php
DB_HOST=`cat wp-config.php | grep "DB_HOST"  | awk "{print $2}"  | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
/bin/sed -i "s/$DB_HOST/localhost/" wp-config.php

/usr/bin/mysql < *.sql
rm -rf *sql
sudo -u www bash /opt/scripts/commit.sh best-editing-services.com
usr/share/essay/alert/slack.sh "satellites" "changes commited by eugene.ryabchuk for satellite [SA-7385]
