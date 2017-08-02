#!/bin/bash

WP_DIR=/var/www/html/
LIST=`cat /home/ec2-user/list`


check_dir () {
  if [ -d "$WP_DIR" ]; then
  cd $WP_DIR && echo "Passed"
  else
	  echo "$WP_DIR - Does not exits, check path"
  exit 255
  fi
}

check_domain_type () {
  if [ -f "$WP_DIR/$DOMAIN/wp-config.php" ]; then
	echo $DOMAIN $(dig +short $DOMAIN) "WP-SITE"
  else
	echo  $DOMAIN $(dig +short $DOMAIN) "OTHER-TYPE"
  fi
}

run_for_all () {
   check_dir
   for DOMAIN in $LIST;
	do check_domain_type; done
}

run_for_all
