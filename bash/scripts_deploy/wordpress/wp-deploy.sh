#!/bin/bash

# run as root 
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#Choose Version of Wordpress
case "$1" in	
	--help|help|\?|-\?|h)		
                echo "Usage: $0 <wpversion> )"
                echo "     <wpversion> : Choose wp version ( example 4.5.1 or latest )";
                echo "";
                exit 0;
                ;;
esac

if test $# -lt 1
then   $0 --help 
        exit 56;
fi

WPVERSION=$1
yourip=`/sbin/ifconfig enp0s3 | grep 'inet' | cut -d: -f2 | awk '{ print $2}'`
# set colors
green=`tput setaf 2`
red=`tput setaf 1`
normal=`tput sgr0`
bold=`tput bold`

# start
echo "${normal}${bold}CENTOS SITE INSTALLER${normal}"
read -p "Installer adds site files to /var/www, are you ready (y/n)? "
[ "$(echo $REPLY | tr [:upper:] [:lower:])" == "y" ] || exit



# Install WP

read -p "Install WordPress (y/n)? " wpFiles

if [ $wpFiles == "y" ]; then
	read -p "Database name: " dbname
	read -p "Database username: " dbuser

	# If you are going to use root ask about it	
	if [ $dbuser == 'root' ]; then
		read -p "${red}root is not recommended. Use it (y/n)?${normal} " useroot

		if [ $useroot == 'n' ]; then
			read -p "Database username: " dbuser
		fi
	else
		useroot='n'
	fi

	read -s -p "Enter a password for user $dbuser: " userpass
	echo " "

	# Create MySQL database
	read -p "Add MySQL DB user and tables (y/n)? " dbadd
	if [ $dbadd == "y" ]; then
		read -s -p "Enter your MySQL root password: " rootpass
		echo " "

		if [ ! -d /var/lib/mysql/$dbname ]; then
			echo "CREATE DATABASE $dbname;" | mysql -u root -p$rootpass

			if [ -d /var/lib/mysql/$dbname ]; then
				echo "${green}New MySQL database ($dbname) was successfully created${normal}"
			else
				echo "${red}New MySQL database ($dbname) faild to be created${normal}"
			fi

		else
			echo "${red}Your MySQL database ($dbname) already exists${normal}"
		fi

		echo "Checking whether the $dbuser exists and has privileges"

		user_exists=`mysql -u root -p$rootpass -e "SELECT user FROM mysql.user WHERE user = '$dbuser'" | wc -c`
		if [ $user_exists = 0 ]; then
			echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$rootpass
			echo "${green}New MySQL user ($dbuser) was successfully created${normal}"
		else
			echo "${red}This MySQL user ($dbuser) already exists${normal}"
		fi

		user_has_privilage=`mysql -u root -p$rootpass -e "SELECT User FROM mysql.db WHERE db = '$dbname' AND user = '$dbuser'" | wc -c`
		if [ $user_has_privilage = 0 ]; then
			echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$rootpass
			echo "FLUSH PRIVILEGES;" | mysql -u root -p$rootpass
			echo "${green}Add privilages for user ($dbuser) to DB $dbname${normal}"
		else 
			echo "${red}User ($dbuser) already has privilages to DB $dbname${normal}"
		fi

	fi

	# Download, unpack and configure WordPress
	read -r -p "Enter your URL without www [e.g. example.com]: " wpURL
	if [ ! -d /var/www/$wpURL ]; then
		cd /var/www
		if [$WPVERSION == 'latest']; then
			wget http://wordpress.org/latest.tar.gz
			tar -xzf latest.tar.gz --transform s/wordpress/$wpURL/
			rm latest.tar.gz
		else
	                wget http://wordpress.org/wordpress-${WPVERSION}.tar.gz
	                tar -xzf wordpress-${WPVERSION}.tar.gz --transform s/wordpress/$wpURL/
			rm wordpress-${WPVERSION}.tar.gz
			fi
			if [ -d /var/www/$wpURL ]; then
				echo "${green}WordPress downloaded.${normal}"
				cd /var/www/$wpURL
				cp wp-config-sample.php wp-config.php
				sed -i "s/database_name_here/$dbname/;s/username_here/$dbuser/;s/password_here/$userpass/" wp-config.php

				mkdir wp-content/uploads
				chmod 640 wp-config.php
				chmod 775 wp-content/uploads
				chown apache: -R /var/www/$wpURL
				if [ -f /var/www/$wpURL/wp-config.php ]; then
					echo "${green}WordPress has been configured."
					echo "${red}Go to wp-config.php and add authentication unique keys and salts.${normal}"
				else
					echo "${red}Created WP files. wp-config.php setup faild, do this manually.${normal}"
				fi
		else
			echo "${red}Failed to create WP files. Install them manually.${normal}"
		fi
	else
		echo "${red}Site folder already exists.${normal}"
	fi

else
	echo "Skipping WordPress install."
fi

# Create Nginx virtual host
read -p "Do you want to install Nginx vhost (y/n)? " nginxFiles

if [ $nginxFiles == "y" ]; then

	if [ -f /etc/nginx/vhosts/$wpURL ]; then
	    echo "${red}This site already has a vhost file.${normal}"
	else

	echo "
server {

        listen   $yourip:80;
        index index.php index.html index.htm;
        server_name $wpURL;
        access_log  /var/log/nginx/${wpURL}.access.log  main;
        error_log /var/log/nginx/${wpURL}.error.log warn;
        set \$root_path "/var/www/$wpURL";

   location / {
        root   \$root_path;
        index  index.html index.htm index.php;
        }
   location ~ \.php$ {
        root \$root_path;
        proxy_read_timeout 61;
        fastcgi_read_timeout 61;
        try_files \$uri \$uri/ =404;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        }

        location ~* ^.+\.(jpg|jpeg|gif|mpg|avi|js|txt|zip|gz|tgz|tar)$
{
        valid_referers none server_names;
        root \$root_path;
        }
}
" > /etc/nginx/vhosts/${wpURL}.conf
fi

	if [ -f /etc/nginx/vhosts/${wpURL}.conf ]; then
		echo "${green}Nginx vhost file created${normal}"
	else
		echo "${red}Nginx vhost failed to install${normal}"
	fi

fi

systemctl restart nginx 

  echo "${green} Add $yourip $wpURL to hosts file and go to http://$wpURL and finish install.${normal}";

