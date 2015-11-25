#!/usr/bin/env bash

#########################  C O N F I G U R A T I O N  #########################
# Use single quotes instead of double to work with special-character passwords

# VuFind2 'install path' ie. mount path of the host's shared folder
INSTALL_PATH='/usr/local/vufind2'
#SOLR_URL='http://localhost:8080/solr'
#SAMPLE_DATA_PATH=''  # eg. /vagrant/violasample.xml, use MARC!

# MySQL
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'

# Timezone
TIMEZONE='Europe/Helsinki'

# Oracle PHP OCI Instant Client (Voyager)
INSTALL_ORACLE=true
INSTALLER_PATH='/vagrant'
# version info
VERSION='12_1'
DOT_VERSION='12.1'
# versions above 12.1 need a new config file to be created
OCI_CONFIG_URL='http://pastebin.com/raw.php?i=20T49aHg'  # 20T49aHg <= v12.1  

###############################################################################

# set timezone
sudo timedatectl set-timezone $TIMEZONE

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2
sudo apt-get install -y apache2

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $INSTALL_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $INSTALL_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# install php 5
sudo apt-get install -y php5 php5-dev php-pear php5-json php5-mcrypt php5-mysql php5-xsl php5-intl php5-gd

# change php.ini: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php5/apache2/php.ini

# install Java JDK
sudo apt-get -y install default-jdk

# enable mod_rewrite
sudo a2enmod rewrite

# link VuFind to Apache
sudo cp -f $INSTALL_PATH/local/httpd-vufind.conf.sample /etc/apache2/conf-available/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$INSTALL_PATH"',' /etc/apache2/conf-available/httpd-vufind.conf
if [ ! -h /etc/apache2/conf-enabled/vufind2.conf ]; then
  sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf
fi

# copy sample configs to ini files
cd $INSTALL_PATH/local/config/finna
for x in *.ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done

cd $INSTALL_PATH/local/config/vufind
for x in *ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done
cp searchspecs.yaml.sample searchspecs.yaml
cd
# modify Solr URL if set
if [ ! -z "$SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *\n,url = '"$SOLR_URL"',' $INSTALL_PATH/local/config/vufind/config.ini
fi

# copy local dir inside virtual machine
sudo mkdir -p /usr/local/vufind2_local
sudo cp -rf $INSTALL_PATH/local/* /usr/local/vufind2_local/
sudo sed -i -e 's,VUFIND_LOCAL_DIR '"$INSTALL_PATH"'/local,VUFIND_LOCAL_DIR /usr/local/vufind2_local,' /etc/apache2/conf-available/httpd-vufind.conf
sudo chown -R vagrant:vagrant /usr/local/vufind2_local
sudo chown -R www-data:www-data /usr/local/vufind2_local/cache

# restart apache
service apache2 restart

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# run local Solr?
if [ "$SOLR_URL" = "http://localhost:8080/solr" ]; then
  sudo $INSTALL_PATH/vufind.sh start
#  if [ -z "$SAMPLE_DATA_PATH" ]; then
#    sudo $INSTALL_PATH/import-marc.sh $SAMPLE_DATA_PATH
#  fi
fi

# Oracle PHP OCI driver
if [ "$INSTALL_ORACLE" = true ] ; then
  sudo pear upgrade pear
  mkdir -p /opt/oracle
  cd /opt/oracle
  sudo apt-get install -y unzip
  sudo unzip -o "$INSTALLER_PATH/*.zip" -d ./
  sudo ln -s /opt/oracle/instantclient_$VERSION/libclntsh.so.* /opt/oracle/instantclient_$VERSION/libclntsh.so
  sudo ln -s /opt/oracle/instantclient_$VERSION/libocci.so.* /opt/oracle/instantclient_$VERSION/libocci.so
  sudo sh -c "echo /opt/oracle/instantclient_$VERSION > /etc/ld.so.conf.d/oracle-instantclient"
  sudo sh -c "echo instantclient,/opt/oracle/instantclient_$VERSION | sudo pecl install oci8" 
  sudo sh -c 'echo extension=oci8.so > /etc/php5/mods-available/oci8.ini'
  sudo ln -s /usr/include/php5 /usr/include/php
  sudo php5enmod oci8
  sudo service apache2 reload

  # PDO_OCI
  sudo pecl channel-update pear.php.net
  sudo mkdir -p /tmp/pear/download/
  cd /tmp/pear/download/
  sudo pecl download pdo_oci
  sudo tar xvf PDO_OCI-*.tgz
  cd PDO_OCI-*
  sudo curl -o config.m4 $OCI_CONFIG_URL
  sudo chmod +x config.m4
  sudo sed -i -e 's/function_entry pdo_oci_functions/zend_function_entry pdo_oci_functions/' pdo_oci.c
  sudo phpize
  sudo mkdir -p /opt/oracle/instantclient_$VERSION/lib/oracle/$DOT_VERSION
  sudo ln -s /opt/oracle/instantclient_$VERSION/sdk /opt/oracle/instantclient_$VERSION/lib/oracle/$DOT_VERSION/client
  sudo ln -s /opt/oracle/instantclient_$VERSION /opt/oracle/instantclient_$VERSION/lib/oracle/$DOT_VERSION/client/lib
  sudo ln -s /usr/include/php5 /usr/include/php
  sudo ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient_$VERSION,$DOT_VERSION
  sudo make
  sudo make install
  sudo sh -c 'echo extension=pdo_oci.so > /etc/php5/mods-available/pdo_oci.ini'
  sudo php5enmod pdo_oci
  sudo service apache2 reload
fi
