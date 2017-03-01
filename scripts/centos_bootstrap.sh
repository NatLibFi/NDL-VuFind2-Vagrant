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

# Add Webstatic repo & update yum
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
sudo yum history new
sudo yum -y update

# install apache
sudo yum -y install httpd
# install php7
sudo yum -y install php70w php70w-devel php70w-intl php70w-mysql php70w-xml php70w-gd php70w-mbstring php70w-mcrypt php70w-curl php70w-pear

# configure php
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php.ini
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php.ini
# fix timezone to suppress PHP errors, use a different timezone if needed
sudo sed -i -e 's,;date.timezone =,date.timezone = "Europe/Helsinki",' /etc/php.ini

# set security settings for Apache
sudo setsebool -P httpd_can_network_relay=1
sudo setsebool -P httpd_can_sendmail=1

# configure firewall
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8983/tcp --permanent
sudo firewall-cmd --reload

# install NDL-Vufind2
if [ "$INSTALL_VUFIND2" = true ]; then
  source /vagrant/scripts/centos_vufind2.sh;
fi

# start Apache
sudo systemctl start httpd
# start Apache at boot
sudo systemctl enable httpd

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
