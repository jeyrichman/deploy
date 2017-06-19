WP_DIR='/var/www/html/*/'



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
elif [ $DB_EXIST == $DB ]; then
        mysql < $WP_DIR/$DB.sql &&
        echo "Dump Deployed"
        mysql -e "GRANT ALL PRIVILEGES ON $DB.* TO root@localhost identified by '123123asd';" &&
        echo "Privileges for $DB has been set"
else
        echo "Something going wrong"
        exit 255
fi
}


rename_configs (): {
if [ -f "$WP_DIR/wp-config.php" ]; then
        mv $WP_DIR/wp-config.php $WP_DIR/wp-config.php-back &&
        mv $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php &&
        echo "Files renamed"
else
        "Do not find a file"
        exit 255
fi
}



#rm $WP_DIR/$DB.sql
