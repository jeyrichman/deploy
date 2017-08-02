#Install libs
yum install gcc perl-devel -y

#Create dirs
mkdir /opt/collectd/
mkdir /var/lib/zabbix/
mkdir /opt/collectd/

#Install Collectd
wget -q https://collectd.org/files/collectd-5.5.0.tar.gz -O /opt/collectd/collectd-5.5.0.tar.gz
tar xvfp /opt/collectd/collectd-5.5.0.tar.gz
rm /opt/collectd/collectd-5.5.0.tar.gz
cd /opt/collectd/collectd-* && ./configure && make all install

#Install Configuration
git clone https://github.com/raboy/deploy.git 
cp deploy/bash/monitoring/collectd/files/collectd.conf  /etc/collectd.conf
cp deploy/bash/monitoring//collectd/files/iostat_collectd_plugin.rb /var/lib/zabbix/iostat_collectd_plugin.rb
cp deploy/bash/monitoring/configurations/collectd/files/tcp.sh /var/lib/zabbix/tcp.sh
cp /opt/collectd/collectd-*/contrib/redhat/init.d-collectd /etc/init.d/collectd
chmod +x /etc/init.d/collectd
chmod +x /var/lib/zabbix/*

#Run Collectd daemon
sudo ln --symbolic /opt/collectd/sbin/collectd /usr/sbin/collectd
sudo ln --symbolic /opt/collectd/sbin/collectdmon /usr/sbin/collectdmon
service collectd start

