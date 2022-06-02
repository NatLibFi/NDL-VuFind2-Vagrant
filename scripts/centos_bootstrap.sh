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

# Add Epel & Remi repos for php & update yum
sudo dnf install -y epel-release
sudo rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi
sudo rpm -Uvh $REMI_MIRROR/enterprise/remi-release-8.rpm
#sudo yum history new
sudo yum -y update

# install neofetch
sudo yum -y install neofetch

# install apache + some tools
sudo yum -y install httpd unzip wget
# install php
sudo dnf module reset php
sudo dnf module enable php:remi-$REMI_PHP_VERSION -y
sudo yum -y install php php-devel php-intl php-mysql php-xml php-gd php-mbstring php-curl php-pear php-soap

# configure php: display_errors = On, short_open_tag = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php.ini
sudo sed -i -e 's/short_open_tag = Off/short_open_tag = On/g' /etc/php.ini
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
if [ "$INSTALL_SOLR" = true ]; then
  source /vagrant/scripts/centos_solr.sh;
fi
if [ "$INSTALL_RECMAN" = true ]; then
  source /vagrant/scripts/centos_recman.sh;
fi
