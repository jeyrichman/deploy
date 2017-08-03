#!/bin/bash

IP=$1
DOMAIN=$2
PATHE=/var/www/html/$DOMAIN

if [ -z "$IP" ]; then
    echo "usage: ./install-db.sh <ip> <domain>"
    exit
fi

/bin/cat <<EOT | /usr/bin/ssh root@$IP /bin/bash
cd $PATHE
sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" $PATHE/wp-config.php
sed -i "/DB_USER/s/'[^']*'/'root'/2" $PATHE/wp-config.php
sed -i "/DB_PASSWORD/s/'[^']*'/'123123asd'/2" $PATHE/wp-config.php

/usr/bin/mysql < $PATHE/*.sql
rm  $PATHE/*.sql
sudo -u www bash /opt/scripts/commit.sh $DOMAIN
/usr/share/essay/alert/slack.sh "satellites" "changes commited by eugene.ryabchuk for satellite $DOMAIN, task [SA-7385]"
EOT
