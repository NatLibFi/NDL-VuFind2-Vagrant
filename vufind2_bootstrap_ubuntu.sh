#!/usr/bin/env bash

#########################  C O N F I G U R A T I O N  #########################
# Use single quotes instead of double to work with special-character passwords

# VuFind2 'install path' ie. mount path of the host's shared folder
INSTALL_PATH='/usr/local/vufind2'
# local directory inside the guest copied from the host
LOCAL_DIR='/usr/local/vufind2_local'
#SOLR_URL='http://localhost:8080/solr'
#SAMPLE_DATA_PATH=''  # eg. /vagrant/violasample.xml, use MARC!

# MySQL
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'

# timezone
TIMEZONE='Europe/Helsinki'

# Oracle PHP OCI Instant Client (Voyager)
INSTALL_ORACLE_CLIENT=true         # make sure you have the installer RPM files
ORACLE_PATH='/vagrant/oracle'      # downloaded here from Oracle Downloads
ORACLE_FILES_EXIST=false           # this must be set to false
CONFIG_PATH='/vagrant/config'      # Voyager config files
# version info
OCI_VERSION='12_1'
OCI_DOT_VERSION='12.1'
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
sudo mkdir -p $LOCAL_DIR
sudo cp -rf $INSTALL_PATH/local/* $LOCAL_DIR
sudo sed -i -e 's,VUFIND_LOCAL_DIR '"$INSTALL_PATH"'/local,VUFIND_LOCAL_DIR '"$LOCAL_DIR"',' /etc/apache2/conf-available/httpd-vufind.conf
sudo chown -R vagrant:vagrant $LOCAL_DIR
sudo chown -R www-data:www-data $LOCAL_DIR/cache

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
for f in $ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip; do
  [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer ZIP files found!"
  break
done
if [ "$INSTALL_ORACLE_CLIENT" = true -a "$ORACLE_FILES_EXIST" = true ] ; then
  sudo pear upgrade pear
  mkdir -p /opt/oracle
  cd /opt/oracle
  sudo apt-get install -y unzip
  sudo unzip -o "$ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip" -d ./
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so.* /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libocci.so.* /opt/oracle/instantclient_$OCI_VERSION/libocci.so
  sudo sh -c "echo /opt/oracle/instantclient_$OCI_VERSION > /etc/ld.so.conf.d/oracle-instantclient"
  sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | sudo pecl install oci8" 
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
  sudo mkdir -p /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/sdk /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION/client
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION/client/lib
  sudo ln -s /usr/include/php5 /usr/include/php
  sudo ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient_$OCI_VERSION,$OCI_DOT_VERSION
  sudo make
  sudo make install
  sudo sh -c 'echo extension=pdo_oci.so > /etc/php5/mods-available/pdo_oci.ini'
  sudo php5enmod pdo_oci
  sudo service apache2 reload

  # sqlplus
  sudo apt-get install -y rlwrap
  echo "alias sqlplus='rlwrap sqlplus'" >> /home/vagrant/.bashrc
  echo "export LD_LIBRARY_PATH=/opt/oracle/instantclient_$OCI_VERSION"  >> /home/vagrant/.bashrc
  echo "export SQLPATH=~/code/oracle-scripts/scripts:/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  echo "PATH=$PATH:/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  echo "export TNS_ADMIN=/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  source /home/vagrant/.bashrc
  if [ -f $ORACLE_PATH/tnsnames.ora ]; then
    cp -rf $ORACLE_PATH/tnsnames.ora /opt/oracle/instantclient_$OCI_VERSION/
  fi

  # conf files
  shopt -s nullglob
  voyagers=($CONFIG_PATH/VoyagerRestful_*.ini)
  shopt -u nullglob
  if [ ${#voyagers[@]} -gt 0 ]; then
    cp -rf $CONFIG_PATH/VoyagerRestful_*.ini $LOCAL_DIR/config/vufind/
    for i in "${voyagers[@]}"; do
      org=$(echo $i| cut -d'_' -f 2| cut -d'.' -f 1)
      sed -i '/\[Drivers\]$/a '"$org"' = VoyagerRestful' $LOCAL_DIR/config/finna/MultiBackend.ini
    done
  fi
fi
