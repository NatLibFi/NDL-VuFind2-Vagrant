#!/bin/bash

#########################  C O N F I G U R A T I O N  #########################
source /vagrant/centos.conf
###############################################################################

# turn SELinux on
sudo setenforce 1
# turn on SELinux at boot
sudo sed -i -e 's/SELINUX=permissive/SELINUX=enforcing/' /etc/sysconfig/selinux
sudo sed -i -e 's/SELINUX=disabled/SELINUX=enforcing/' /etc/sysconfig/selinux

# set timezone
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# update system
sudo yum -y update

# install apache
sudo yum -y install httpd
# install php5.6 from Webtatic
sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
sudo yum -y install php56w php56w-devel php56w-intl php56w-mysql php56w-xsl php56w-gd php56w-mbstring php56w-mcrypt php56w-curl php56w-pear

# configure php
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php.ini
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php.ini
# fix timezone to suppress PHP errors, use a different timezone if needed
sudo sed -i -e 's,;date.timezone =,date.timezone = "Europe/Helsinki",' /etc/php.ini

# set security settings for Apache
sudo setsebool -P httpd_can_network_relay=1
sudo setsebool -P httpd_can_sendmail=1

# configure firewall
sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
sudo /etc/init.d/iptables save

# install NDL-Vufind2
if [ "$INSTALL_VUFIND2" = true ]; then
  source /vagrant/scripts/centos_vufind2.sh;
fi

# start Apache
sudo service httpd start
# start Apache at boot
sudo chkconfig httpd on

# additional installs
if [ "$INSTALL_ORACLE_CLIENT" = true ]; then
  source /vagrant/scripts/centos_oracle.sh;
fi
if [ "$INSTALL_SOLR" = true ]; then
  source /vagrant/scripts/centos_solr.sh;
fi
if [ "$INSTALL_RECMAN" = true ]; then
  source /vagrant/scripts/centos_recman.sh;
fi
