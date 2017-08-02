#!/bin/bash
set -o pipefail

curtime=`date +%s`
timeout 6 sudo /var/lib/zabbix/check_tcp_connections.sh | sed 's/\ /\n/g' | HOST=`hostname -f | sed 's/\./_/g'` awk -F":" '{print "PUTVAL " ENVIRON["HOST"] "/tcpconns/gauge-"$1" interval=10 NNN:"$2}' > /tmp/conn-new.tmp

if [ "$?" -ne "0" ]; then
    cat /tmp/conn-old.tmp | sed "s/NNN/$curtime/g"
    else
    cat /tmp/conn-new.tmp | sed "s/NNN/$curtime/g"
    mv /tmp/conn-new.tmp /tmp/conn-old.tmp
fi
