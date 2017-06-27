DOMAIN=$1
WP_DIR=/var/www/html/$DOMAIN



deploy_dump () {
if [ -f "$WP_DIR/wp-config.php" ]; then
	DB=`cat $WP_DIR/wp-config.php | grep "DB_NAME" |awk '{print $2}' |cut -d ')' -f1 |cut -d "'" -f2`
	sed -i "s/database_name_here/$DB/" $WP_DIR/wp-config-sample.php &&
	sed -i "s/username_here/root/" $WP_DIR/wp-config-sample.php &&
	sed -i "s/password_here/123123asd/" $WP_DIR/wp-config-sample.php &&
	echo "WP config changed"
else
	echo "Do not find a file"
	exit 255

DB_EXIST=`mysql -e "show databases\G" | grep $DB | awk '{print $2}'`
if [ $DB_EXIST != $DB ]; then
	mysql < $WP_DIR/$DB.sql &&
	echo "Dump Deployed"
        mysql -e "GRANT ALL PRIVILEGES ON $DB.* TO root@localhost identified by '123123asd';" &&
        echo "Privileges for $DB has been set"
	rm $WP_DIR/$DB.sql
else
	echo "Dump exist $DB_EXIST or something going wrong"
	exit 255
fi
fi
}


rename_configs () {
if [ -f "$WP_DIR/wp-config.php" ]; then
	mv $WP_DIR/wp-config.php $WP_DIR/wp-config.php-back &&
	mv $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php &&
	echo "Files renamed"
else
	"Do not find a file"
	exit 255
fi
}

set_crt () {
if [ ! -d "$WP_DIR/crt" ]; then
        git clone http://eugene.ryabchuk@satellites-git.uncomp.com/wp-sites/wp-skelet.git
	mv $WP_DIR/wp-skelet/crt $WP_DIR/crt
	echo "Crt installed"
        rm /var/www/crt-issued
	rm -rf $WP_DIR/wp-skelet/
	puppet agent -t
	/etc/init.d/nginx restart
else
	echo "Crt dir exist"
fi
}
#deploy_dump
#rename_configs
#set_crt
