#!/usr/bin/env bash

#########################  C O N F I G U R A T I O N  #########################
source /vagrant/ubuntu.conf
###############################################################################

# set timezone
sudo timedatectl set-timezone $TIMEZONE

# supress irrelevant stdin errors
sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# add Java 8 repository
sudo apt-add-repository -y ppa:webupd8team/java

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install unzip; this may come handy later on
sudo apt-get install -y unzip

# install apache 2
sudo apt-get install -y apache2

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
# fix mysqld options errors
sudo sed -i -e '0,/key_buffer\t/s//key_buffer_size\t/' /etc/mysql/my.cnf
sudo sed -i -e 's/myisam-recover\s\{2,\}/myisam-recover-options\t/' /etc/mysql/my.cnf

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $VUFIND2_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $VUFIND2_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# install php 5
sudo apt-get install -y php5 php5-dev php-pear php5-json php5-mcrypt php5-mysql php5-xsl php5-intl php5-gd php5-curl

# change php.ini: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php5/apache2/php.ini

# install Java JDK. Solr 6 requires Java 8
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

# enable mod_rewrite & mod_headers
sudo a2enmod rewrite
sudo a2enmod headers

# link VuFind to Apache
sudo cp -f $VUFIND2_PATH/local/httpd-vufind.conf.sample /etc/apache2/conf-available/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$VUFIND2_PATH"',' /etc/apache2/conf-available/httpd-vufind.conf
if [ ! -h /etc/apache2/conf-enabled/vufind2.conf ]; then
  sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf
fi

# Config file extensions
CfgExt=( ini yaml json )

# copy sample configs to ini files
cd $VUFIND2_PATH/local/config/finna
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      cp $x $t
    fi
  done
done

cd $VUFIND2_PATH/local/config/vufind
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      cp $x $t
    fi
  done
done

cd

# modify Solr URL if set
if [ ! -z "$EXTERNAL_SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *,url = '"$EXTERNAL_SOLR_URL"',' $VUFIND2_PATH/local/config/vufind/config.ini
fi

# install Composer (globally)
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
cd /vufind2
/usr/local/bin/composer install --no-plugins --no-scripts
cd

# restart apache
service apache2 reload

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# install node.js v5 & less 2.4.0 (for -x option)
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g less@2.4.0

# additional installs
if [ "$INSTALL_ORACLE_CLIENT" = true ]; then
  source /vagrant/scripts/ubuntu_oracle.sh;
fi
if [ "$INSTALL_SOLR" = true -o "$INSTALL_RM" = true ]; then
  source /vagrant/scripts/ubuntu_solr-rm.sh;
fi
