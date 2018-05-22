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

# Add Epel & Webtatic repos for php7 & update yum
sudo rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
sudo yum history new
sudo yum -y update

# install apache
sudo yum -y install httpd
# install php7
sudo yum -y install php71w php71w-devel php71w-intl php71w-mysql php71w-xml php71w-gd php71w-mbstring php71w-mcrypt php71w-curl php71w-pear

# configure php: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php.ini
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php.ini
# set memory_limit
if [[ "$PHP_MEMORY_LIMIT" != "128M" ]]; then
  sudo sed -i -e 's/memory_limit = 128M/memory_limit = '"$PHP_MEMORY_LIMIT"'/' /etc/php.ini
fi
# fix timezone to suppress PHP errors
sudo sed -i -e 's,;date.timezone =,date.timezone = "'"$TIMEZONE"'",' /etc/php.ini

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
