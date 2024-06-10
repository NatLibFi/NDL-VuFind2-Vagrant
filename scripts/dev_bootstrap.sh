#!/usr/bin/env bash

#########################  C O N F I G U R A T I O N  #########################
source /vagrant/dev.conf
###############################################################################

# remove unattended-upgrades
sudo apt-get remove -y unattended-upgrades

# set timezone
sudo timedatectl set-timezone $TIMEZONE

# supress irrelevant stdin errors
export DEBIAN_FRONTEND=noninteractive
sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install unzip & neofetch; these may come handy later on
sudo apt-get install -y unzip neofetch

# install Apache 2
sudo apt-get install -y apache2

# enable mod_rewrite & mod_headers
sudo a2enmod rewrite
sudo a2enmod headers

# install PHP
echo | sudo add-apt-repository ppa:ondrej/php
sudo apt-get install -y php$PHP_VERSION libapache2-mod-php$PHP_VERSION php$PHP_VERSION-dev php-pear php-json php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-intl php$PHP_VERSION-gd php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-soap php$PHP_VERSION-common php$PHP_VERSION-ldap php$PHP_VERSION-zip

if [ -z "$PHP_VERSION" ]; then
  sudo phpenmod mbstring
else
  sudo phpenmod -v $PHP_VERSION mbstring
  sudo update-alternatives --set php /usr/bin/php$PHP_VERSION
  sudo update-alternatives --set phar /usr/bin/phar$PHP_VERSION
  sudo update-alternatives --set phar.phar /usr/bin/phar.phar$PHP_VERSION
  sudo update-alternatives --set phpize /usr/bin/phpize$PHP_VERSION
  sudo update-alternatives --set php-config /usr/bin/php-config$PHP_VERSION
fi

# configure php: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php/???/apache2/php.ini
# for PHP 7.x
if [ -z /etc/php/7*/apache2/php.ini ]; then
  sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php/7*/apache2/php.ini;
fi
# for PHP 8.x (not really needed see https://php.watch/versions/8.0/JIT#jit-opcache.enable )
if [ -z /etc/php/8*/apache2/php.ini ]; then
  sudo sed -i -e 's/^opcache.enable=1/;opcache.enable=1/' /etc/php/8*/apache2/php.ini
fi
# set memory_limit
if [[ "$PHP_MEMORY_LIMIT" != "128M" ]]; then
  sudo sed -i -e 's/memory_limit = 128M/memory_limit = '"$PHP_MEMORY_LIMIT"'/' /etc/php/???/apache2/php.ini
fi

# install NDL-Vufind2
if [ "$INSTALL_VUFIND2" = true ]; then
  source /vagrant/scripts/dev_vufind2.sh;
fi

# restart Apache
if [ ! -z "$PHP_VERSION" ]; then
  sudo a2enmod php$PHP_VERSION
fi
sudo service apache2 reload

# additional installs
if [ "$INSTALL_IMGSERVICE" = true ]; then
  source /vagrant/scripts/dev_imgservice.sh
fi
if [ "$INSTALL_SOLR" = true ]; then
  source /vagrant/scripts/dev_solr.sh
fi
if [ "$INSTALL_RECMAN" = true ]; then
  source /vagrant/scripts/dev_recman.sh
fi
if [ "$INSTALL_ADMINTERFACE" = true ]; then
  source /vagrant/scripts/dev_adminterface.sh
fi