#!/bin/bash

MyUSER="dbuser"
MyPASS="dbpass"
MyHOST="localhost"
 
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

#MYSQL="/usr/local/bin/mysql"
#MYSQLDUMP="/usr/local/bin/mysqldump"

CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"
 
DEST="./db_backup"
 
MBD="$DEST"
HOST="$(hostname)"
NOW="$(date +"%Y%m%d")"
 
FILE=""
DBS=""
 
# DO NOT BACKUP these databases, delemiter SPACE
IGN="information_schema"

# Get all database list first
DBS="$($MYSQL -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"

for db in $DBS
do

    skipdb=-1
    if [ "$IGN" != "" ]; then
        for i in $IGN
        do
            [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi
 
    if [ "$skipdb" == "-1" ] ; then
        MBD="$DEST/$db"    	
        [ ! -d $MBD ] && mkdir -p $MBD || :
        FILE="$MBD/$NOW.sql.gz"
            $MYSQLDUMP --opt -u $MyUSER -h $MyHOST -p$MyPASS $db | $GZIP -9 > $FILE
        FNUM="$(find $MBD/* | wc -l)"
        if [ $FNUM -ge 0 ] ; then
            find $MBD/* -type f -mtime 20 -exec rm -rf {} \;
        fi
    fi

done
