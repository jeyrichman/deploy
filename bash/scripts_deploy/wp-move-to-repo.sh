#!/bin/bash

#General VARS
GIT_TOKEN="YOUR_TOKEN"
GIT_PROJECT=`echo $SITENAME | sed 's/\./\-/g'`
WP_DIR=/var/www/html/$SITENAME
LIST=/root/list

check_dir () {
if [ -d "$WP_DIR" ]; then
cd $WP_DIR
else
echo "$WP_DIR - Does not exits, check path"
exit 255
fi
}

create_dump () {
DB_NAME=`cat $WP_DIR/$SITENAME/wp-config.php | grep DB_NAME | awk -F", '" '{print $2}' | awk -F"'" '{print $1}'`
if [ -f "$DB_NAME" ]; then
/usr/bin/mysqldump -B $DB_NAME > $WP_DIR/$SITENAME/$DB_NAME.sql
else
echo "$DB_NAME - No wp-config.php file, please chech"
exit 255
fi
}

create_deploy_repo () {
curl --header "PRIVATE-TOKEN: $GIT_TOKEN" -X POST "http://satellites-git.example.com/api/v3/projects?name=$GIT_PROJECT&namespace_id=2" 2>/dev/null &&
cd $WP_DIR/ && #rm .bash*
git init && git remote add origin http://user@satellites-git.example.com/html-sites/$GIT_PROJECT.git
git add . &&
git commit -m "Added $SITENAME" &&
git push -u origin master &&
echo "Domain $SITENAME been pushed to repository"
}


for SITENAME in `cat $LIST`;do
check_dir
create_dump
create_deploy_repo
done
