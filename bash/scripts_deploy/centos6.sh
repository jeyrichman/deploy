#!/bin/sh


case "$1" in
	--help|help|\?|-\?|h)
		echo "";
		echo "Usage: $0";
		echo "";
		echo "or";
		echo "";
		echo "Usage: $0 <hostname> <ethernet_dev> (<ip>)";
		echo "     <hostname> : Your server's hostname ( example DS1111 )";
		echo " <ethernet_dev> : Your ethernet device with the server IP ( example eth0 )";
		echo "           <ip> : Optional.  Use to override the IP in <ethernet_dev> ( example 1.1.1.1-3,2.3.4.5) ";
		echo "";
		exit 0;
		;;
esac
SERVERHOSTNAME=$1
ETH_DEV=$2;
IPS=`echo $3 | sed 's/,/ /g'`
sed -i '/^search/d' /etc/resolv.conf

if test $# -lt 2
then
	$0 --help
        exit 56;
fi

if [ -e /usr/local/directadmin ]; then
	echo "";
	echo "";
	echo "*** DirectAdmin already exists ***";
	echo "";
	echo "";
	exit 56;
fi

if [ -e /usr/local/cpanel ]; then
        echo "";
        echo "";
        echo "*** CPanel exists on this system ***";
        echo "";
        echo "";
        exit 56;
fi

	hostname ${SERVERHOSTNAME}.clientshostname.com
	sed -i "s/HOSTNAME=.*$/HOSTNAME=${SERVERHOSTNAME}\.clientshostname\.com/" /etc/sysconfig/network

	yum -y install perl bzip2 smartmontools
#	cpan -i Crypt::PasswdMD5 

ADMINROOTPASS=`perl -e 'for(0..14){$$p.=(0..9,"A".."Z","a".."z")[rand 62];}print "$$p\n";'`
ROOTPASS=`perl -e 'for(0..14){$$p.=(0..9,"A".."Z","a".."z")[rand 62];}print "$$p\n";'`
MYSQLROOTPASS=`perl -e 'for(0..14){$$p.=(0..9,"A".."Z","a".."z")[rand 62];}print "$$p\n";'`
MYIP=`ifconfig  | grep 'inet addr' | head -n 1 | awk -F ":" '{print $2}' | awk '{print $1}'`

#set time
echo "set time"
	rm -rf /etc/localtime
	cp /usr/share/zoneinfo/UTC /etc/localtime

#adduser adminroot
echo "adduser"
	adduser -G wheel -m adminroot
	chmod 755 /home/adminroot
	echo ${ADMINROOTPASS} | passwd --stdin adminroot
	echo ${ROOTPASS} | passwd --stdin root

	echo -n > /etc/motd
	echo "echo \`last |head ;date\` | mail -s 'server $SERVERHOSTNAME is up' notify@notify.king-support.com" >> /etc/rc.local

# Configure /etc/ssh/sshd_config
echo "Configure /etc/ssh/sshd_config"
	echo ChallengeResponseAuthentication no >> /etc/ssh/sshd_config
	echo PasswordAuthentication yes >> /etc/ssh/sshd_config
	echo PermitRootLogin without-password >> /etc/ssh/sshd_config
	echo Port 22 >> /etc/ssh/sshd_config
	echo Port 222 >> /etc/ssh/sshd_config
	echo MaxStartups 10:30:60 >> /etc/ssh/sshd_config
	perl -i -pe 's/^#?UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	mkdir /root/.ssh
	wget -q http://data.king-support.com/distfiles/defaults/authorized_keys -O /root/.ssh/authorized_keys
	/etc/init.d/sshd restart

#disable selinux
echo "disable selinux"
	echo 0 > /selinux/enforce
	setenforce 0
	perl -i -pe 's/^#?SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#config yum
echo "config yum"
	rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms
	wget -q http://data.king-support.com/distfiles/centos/dag.repo -O /etc/yum.repos.d/dag.repo
	wget -q http://data.king-support.com/distfiles/centos/atrpms.repo -O /etc/yum.repos.d/atrpms.repo
#	wget http://data.king-support.com/distfiles/centos/remi-enterprise.repo -O /etc/yum.repos.d/remi-enterprise.repo
#	wget http://data.king-support.com/distfiles/centos/atomic.repo -O /etc/yum.repos.d/atomic.repo
#	wget http://data.king-support.com/distfiles/centos/centos-testing.repo -O /etc/yum.repos.d/centos-testing.repo
        cd /root/
        wget -q http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-5.noarch.rpm
        rpm -i epel-release-6-5.noarch.rpm
	rm -f /root/epel-release-6-5.noarch.rpm
	echo 'exclude=apache* httpd* mod_* php* nginx*' >> /etc/yum.conf
	yum makecache

#disable soft
echo "disable soft"
	for i in portmap avahi-daemon cups bluetooth ip6tables sendmail postfix; do
		/etc/init.d/$i stop
		chkconfig $i off
	done

#soft
echo "soft"
	yum -y install ntp mc net-snmp gd-devel sysstat gcc-c++ gcc automake autoconf libtool make libxml2-devel curl-devel GeoIP-devel GeoIP screen ImageMagick nload libjpeg-devel libpng-devel openssl-devel mlocate vim openssh-clients rsync cronie || (echo error ; sleep 10 ; exit 99)
	ntpdate -bs 66.250.131.190 64.136.200.96 132.236.56.250

#vsftpd
echo "vsftpd"
	yum -y install vsftpd
	touch /etc/vsftpd/chroot_list
	wget -q http://data.king-support.com/distfiles/defaults/vsftpd.conf -O /etc/vsftpd/vsftpd.conf
	chmod 600 /etc/vsftpd/vsftpd.conf
	/etc/init.d/vsftpd start
	chkconfig vsftpd on

#mysql 
echo "mysql"
	yum -y install mysql-server mysql-devel
	wget -q http://data.king-support.com/distfiles/defaults/my.cnf -O /etc/my.cnf
	/etc/init.d/mysqld start
	/usr/bin/mysqladmin -u root password ${MYSQLROOTPASS}
	echo '[client]' > /root/.my.cnf
	echo password=${MYSQLROOTPASS} >> /root/.my.cnf
	chkconfig mysqld on


if uname -m | grep -q 64 ; then
	echo "doing 64 bit changes"
	ln -s /usr/lib64 /opt/lib
	ln -s /usr/include /opt/include
	yum -y install libjpeg-devel libpng-devel
fi

#httpd and php
echo "httpd and php"
	mkdir /usr/work /usr/local/share/GeoIP
	wget -q http://data.king-support.com/distfiles/work.tar.gz -O /usr/work/work.tar.gz
	tar zxfp /usr/work/work.tar.gz -C /usr/
	if uname -m | grep -q 64 ; then
		sed -i -e 's|with-mysql=/usr/|with-mysql=/usr/lib64/mysql/|' /usr/work/src/do_php5.sh
		sed -i -e 's|--with-jpeg-dir|--with-jpeg-dir \\|' /usr/work/src/do_php5.sh
		sed -i -e 's|# --with-libdir=/lib64| --with-libdir=/lib64|' /usr/work/src/do_php5.sh
	fi
	cd /usr/local/share/GeoIP > /dev/null 2>&1 && wget -q http://data.king-support.com/distfiles/Latest/GeoIP.dat.gz > /dev/null 2>&1 && gunzip -f GeoIP.dat.gz
	wget -q http://data.king-support.com/distfiles/Latest/php5.tar.gz -O /usr/work/src/php5.tar.gz
	wget -q http://data.king-support.com/distfiles/Latest/httpd22.tar.gz -O /usr/work/src/httpd22.tar.gz
	wget -q http://data.king-support.com/distfiles/Latest/mod_geoip2.tar.gz -O /usr/work/src/mod_geoip2.tar.gz
	cd /usr/work/src
	tar zxfp /usr/work/src/php5.tar.gz
	tar zxfp /usr/work/src/httpd22.tar.gz
	tar zxfp mod_geoip2.tar.gz
	ln -s /usr/work/src/php-5.2* /usr/work/src/php5
	ln -s /usr/work/src/httpd-2.2* /usr/work/src/apache2
	/usr/work/src/do_apache2.sh
	/usr/work/src/do_php5.sh
	wget -q http://data.king-support.com/distfiles/defaults/php.ini -O /usr/local/lib/php.ini
	/usr/work/src/do_zend.sh
	mkdir /usr/local/apache2/conf/vhost/ /home/logs /etc/httpd 
	ln -s /usr/local/apache2/conf /etc/httpd/conf

	wget -q http://data.king-support.com/distfiles/defaults/httpd.conf -O /usr/local/apache2/conf/httpd.conf
	wget -q http://data.king-support.com/distfiles/defaults/82port.conf.orig -O /usr/local/apache2/conf/vhost/82port.conf.orig
	wget -q http://data.king-support.com/distfiles/centos/httpd.initd -O /etc/init.d/httpd
	chmod 755 /etc/init.d/httpd
	chkconfig --add httpd
	chkconfig httpd on
	sed -e "s/IP/${MYIP}/" /usr/local/apache2/conf/vhost/82port.conf.orig > /usr/local/apache2/conf/vhost/82port.conf
	
	#securing apache
	useradd -c 'apache user' -M -r -s /sbin/nologin www
		
	#Changing httpd.conf. Later it will be changed already.
	sed -i -e 's/adminroot/www/g' /usr/local/apache2/conf/httpd.conf
	
#phpmyadmin
echo "phpmyadmin"
	mkdir /home/admin
	mkdir /home/admin/apache_mon
	mkdir /home/admin/apache_mon/mrtg
	wget -q http://data.king-support.com/distfiles/Latest/phpMyAdmin.tbz -O /home/admin/apache_mon/phpMyAdmin.tbz
	tar -xzpf /home/admin/apache_mon/phpMyAdmin.tbz -C /home/admin/apache_mon
	rm -f /home/admin/apache_mon/phpMyAdmin.tbz
	mv /home/admin/apache_mon/phpMyAdmin* /home/admin/apache_mon/phpmyadmin
	rm -rf /home/admin/apache_mon/www /home/admin/apache_mon/+* /home/admin/phpmyadmin*.md5
	cp /home/admin/apache_mon/phpmyadmin/config.sample.inc.php /home/admin/apache_mon/phpmyadmin/config.inc.php
	perl -i -pe "s/'cookie'/'http'/" /home/admin/apache_mon/phpmyadmin/config.inc.php
	chmod 644 /home/admin/apache_mon/phpmyadmin/config.inc.php


	yum -y install perl-libwww-perl
	yum -y install perl-DBD-MySQL

	for item in {postest.cgi,xtest.php,xtestnew.cgi,zend.php}; do
		wget -q http://data.king-support.com/distfiles/defaults/test.cgi/$item -O /home/admin/apache_mon/$item
		if echo $item|grep cgi; then
			chmod +x /home/admin/apache_mon/$item
		fi
	done

	/etc/init.d/httpd restart
	ln -s /usr/local/apache2/bin/htpasswd /usr/local/bin/htpasswd
	ln -s /usr/local/apache2/bin/apachectl /usr/local/bin/apachectl
	ln -s /usr/local/apache2/bin/suexec /usr/local/bin/suexec

#iptables
echo "iptables"
	iptables -I INPUT -j ACCEPT
	/etc/init.d/iptables save

#mon and rrd graf
echo "mon rrd graf"
	yum -y install rrdtool
	/usr/work/scripts/mon/rrdtool/rrd_create_host.pl
	ln -s /usr/work/scripts/mon/rrdtool/web/ /home/admin/apache_mon/web
	wget -q http://data.king-support.com/distfiles/defaults/mon -O /etc/logrotate.d/mon
	/etc/init.d/rsyslog restart

#crontab
echo "crontab"
	wget -q http://data.king-support.com/distfiles/defaults/crontab.add -O /root/crontab.add
	crontab -lu root > /root/crontab.now
	cat /root/crontab.now >> /root/crontab.add
	crontab -u root /root/crontab.add
	/etc/init.d/crond restart

#add ips
if [ $# -gt 2 ]; then
	echo "add ips"
	/usr/work/scripts/add_ips.pl -notest=1 -dev=$ETH_DEV $IPS
fi

#exim
echo "exim"
	yum -y install exim dovecot perl-Crypt-PasswdMD5
	useradd -d /var/spool/exim -s /sbin/nologin -g mail exim
	mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
	wget -q http://data.king-support.com/distfiles/defaults/dovecot-2.conf -O /etc/dovecot/dovecot.conf
	wget -q http://data.king-support.com/distfiles/defaults/exim.tar.gz -O /etc/exim/exim.tar.gz
	tar zxfp /etc/exim/exim.tar.gz -C /etc
	ip ad li $ETH_DEV | grep "inet " | awk '{print $2}' | awk -F "/" '{print $1}' >> /etc/exim/dbm/relay_from_host
	perl -i -pe "s/CHANGE_HOSTNAME/${SERVERHOSTNAME}\.clientshostname\.com/" /etc/exim/exim.conf
	sed -i -e 's/mailnull/exim/' /etc/exim/exim.conf
	sed -i -e 's/exim_group = mail/exim_group = exim/' /etc/exim/exim.conf
	mkdir /var/mail/exim
	chmod 777 /var/mail/exim
	chgrp mail /usr/libexec/dovecot/deliver
	chmod 04750 /usr/libexec/dovecot/deliver
	mkdir /etc/exim/domain
	alternatives --set mta /usr/sbin/sendmail.exim
	/etc/init.d/postfix stop
	/etc/exim/dbm/make.sh
	/etc/init.d/exim start
	/etc/init.d/dovecot start
	chkconfig postfix off
	chkconfig exim on
	chkconfig dovecot on
        mv /usr/work/scripts/mon/conf/mon.centos6 /usr/work/scripts/mon/conf/mon.conf.linux

#nginx
echo "nginx"
	yum -y install pcre-devel
	wget -q http://data.king-support.com/distfiles/Latest/nginx.tar.gz -O /usr/work/src/nginx.tar.gz
	cd /usr/work/src
	tar zxfp /usr/work/src/nginx.tar.gz
	cd /usr/work/src/nginx*
	./configure
	make -s install
	mkdir /usr/local/nginx/conf/vhost
	wget -q http://data.king-support.com/distfiles/defaults/nginx.conf -O /usr/local/nginx/conf/nginx.conf
	ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx
	wget -q http://data.king-support.com/distfiles/centos/nginx.initd -O /etc/init.d/nginx
	chmod 755 /etc/init.d/nginx
	chkconfig --add nginx
	chkconfig nginx on

#4 panel
echo "Panel info"
	echo ${SERVERHOSTNAME}
	echo '----- Access ----------------------'
	echo adminroot / ${ADMINROOTPASS}
	echo root / ${ROOTPASS}
	echo mysqlroot / ${MYSQLROOTPASS}
	echo '----- IPs -------------------------'
	echo $MYIP
	echo $IPS | sed 's/ /\n/g'
	echo '----- Hardware --------------------'
	cat /proc/cpuinfo | grep "model name" | head -n 1
	cat /proc/meminfo | grep MemTotal
	head -n 1 /etc/issue
	echo -n > /etc/smartd.conf
	NEXT=1
	for SDEV in `cat /proc/partitions | awk '{print $4}' |grep -v -E "name|dm|md" | cut -c 1,2,3 | uniq | awk '{print "/dev/"$1}' | grep -v -e "^/dev/$"`
	do
        	for i in ata scsi marvell sat ;
	        do
			if [ $NEXT = 1 ]
			then
	        	        TYPE=`smartctl -d $i -i $SDEV | grep -c "Device Model"`;
        	        	if [ $TYPE = 1 ]
	        	        then
        	        	        smartctl -i -d $i $SDEV | grep -A 4 "Device Model"
					if ! smartctl -i -d $i $SDEV | grep -q QEMU ; then
						smartctl -d $i $SDEV -t long >> /dev/null
						echo "$SDEV -d $i -a -m notify@notify.king-support.com,root@localhost -M once -s L/../../2/01" >> /etc/smartd.conf
					fi
        	                	echo
					NEXT=0
	        	        fi
			fi
        	done
		NEXT=1
	done
	/etc/init.d/smartd restart
