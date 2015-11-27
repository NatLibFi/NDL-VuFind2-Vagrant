#!/bin/bash

#########################  C O N F I G U R A T I O N  #########################
# Use single quotes instead of double to work with special-character passwords

# VuFind2 install path in the guest machine
INSTALL_PATH='/usr/local/vufind2'
#SOLR_URL='http://localhost:8080/solr'
#SAMPLE_DATA_PATH=''  # eg. /vagrant/violasample.xml, use MARC!

# GitHub
GITHUB_USER='NatLibFi'

# MySQL
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'

# timezone
TIMEZONE='Europe/Helsinki'

# Oracle PHP OCI Instant Client (Voyager)
INSTALL_ORACLE_CLIENT=true         # make sure you have the installer ZIP files
ORACLE_PATH='/vagrant/oracle'      # downloaded here from Oracle Downloads
ORACLE_FILES_EXIST=false           # this must be set to false
# version info
OCI_VERSION='12.1'
# versions above 12.1 need a new config file to be created
OCI_CONFIG_URL='http://pastebin.com/raw.php?i=20T49aHg'  # 20T49aHg <= v12.1  

###############################################################################

# turn SELinux on
sudo setenforce 1

# set timezone
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# update system
sudo yum -y update

# install git & clone repository
sudo yum -y install git
sudo mkdir -p $INSTALL_PATH
cd $INSTALL_PATH
sudo git clone https://github.com/$GITHUB_USER/NDL-VuFind2.git .
# if you want to be prompted for password, use the line below instead
# sudo git clone https://$GITHUB_USER@github.com/$GITHUB_USER/NDL-VuFind2.git .

# set-up configuration files
sudo cp local/httpd-vufind.conf.sample local/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$INSTALL_PATH"',' local/httpd-vufind.conf
cd $INSTALL_PATH/local/config/finna
for x in *.ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    sudo cp $x $t
  fi
done
cd $INSTALL_PATH/local/config/vufind
for x in *ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    sudo cp $x $t
  fi
done
cp searchspecs.yaml.sample searchspecs.yaml
cd
# modify Solr URL if set
if [ ! -z "$SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *\n,url = '"$SOLR_URL"',' $INSTALL_PATH/local/config/vufind/config.ini
fi

# install apache & php
sudo yum -y install httpd
if [ ! -f /etc/php.ini ]; then
  sudo yum -y install php php-devel php-intl php-mysql php-xsl php-gd php-mbstring php-mcrypt
fi

# we need php > 5.3, replace with latest from webtatic
if php --version | grep -q "PHP 5.3"; then
  sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
  sudo yum -y install yum-plugin-replace
  sudo yum -y replace php-common --replace-with=php56w-common
  sudo yum -y remove php-pear
  sudo rm -rf /usr/share/pear 
  sudo yum -y install php56w-pear
fi

# configure php
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php.ini
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php.ini
# fix timezone to suppress PHP errors, use a different timezone if needed
sudo sed -i -e 's,;date.timezone =,date.timezone = "Europe/Helsinki",' /etc/php.ini

# install java
sudo yum -y install java-*-openjdk-devel

# install mysql
sudo yum -y install mysql-server
sudo service mysqld start

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $INSTALL_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $INSTALL_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -e "$SQL"

# set security settings for Apache
sudo chcon -R unconfined_u:object_r:httpd_sys_content_t:s0 /usr/local/vufind2/
sudo setsebool -P httpd_can_network_relay=1
sudo setsebool -P httpd_can_sendmail=1

# give Apache permissions to use the cache
sudo chown -R apache:apache /usr/local/vufind2/local/cache
sudo chcon -R unconfined_u:object_r:httpd_sys_rw_content_t:s0 /usr/local/vufind2/local/cache

# link VuFind2 to Apache
sudo chcon system_u:object_r:httpd_config_t:s0 /usr/local/vufind2/local/httpd-vufind.conf
if [ ! -h /etc/httpd/conf.d/vufind2.conf ]; then
  sudo ln -s /usr/local/vufind2/local/httpd-vufind.conf /etc/httpd/conf.d/vufind2.conf
fi

# create VuFind2 logfile
sudo touch /var/log/vufind2.log
sudo chown apache:apache /var/log/vufind2.log

# set environment variables (common for all users)
sudo su -c 'echo export VUFIND_HOME="/usr/local/vufind2"  > /etc/profile.d/vufind.sh'
sudo su -c 'echo export VUFIND_LOCAL_DIR="/usr/local/vufind2/local"  >> /etc/profile.d/vufind.sh'
sudo su -c 'source /etc/profile.d/vufind.sh'

# configure firewall
sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
sudo /etc/init.d/iptables save

# start Apache
sudo service httpd start

# start Apache & MySQL at boot
sudo chkconfig httpd on
sudo chkconfig mysqld on

# turn on SELinux at boot
sudo sed -i -e 's/SELINUX=permissive/SELINUX=enforcing/' /etc/sysconfig/selinux
sudo sed -i -e 's/SELINUX=disabled/SELINUX=enforcing/' /etc/sysconfig/selinux

# run local Solr?
if [ "$SOLR_URL" = "http://localhost:8080/solr" ]; then
  sudo $INSTALL_PATH/vufind.sh start
#  if [ -z "$SAMPLE_DATA_PATH" ]; then
#    sudo $INSTALL_PATH/import-marc.sh $SAMPLE_DATA_PATH
#  fi
fi

# Oracle PHP OCI driver
for f in $ORACLE_PATH/oracle-instantclient$OCI_VERSION*.x86_64.rpm; do
  [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer RPM files found!"
  break
done
if [ "$INSTALL_ORACLE_CLIENT" = true -a "$ORACLE_FILES_EXIST" = true ] ; then
  #sudo pear upgrade pear
  sudo yum -y install libaio
  mkdir -p /tmp/oracle
  cd /tmp/oracle
  sudo cp $ORACLE_PATH/oracle-instantclient$OCI_VERSION*.x86_64.rpm ./
  sudo rpm -Uvh oracle-instantclient$OCI_VERSION*-basic-*.x86_64.rpm
  sudo rpm -Uvh oracle-instantclient$OCI_VERSION*-devel-*.x86_64.rpm
  sudo chcon -t textrel_shlib_t /usr/lib/oracle/$OCI_VERSION/client64/lib/*.so
  #sudo execstack -c /usr/lib/oracle/$VERSION/client64/lib/*.so.*
  sudo setsebool -P httpd_execmem 1
  sudo yum -y install gcc
  sudo sh -c "echo /usr/lib/oracle/$OCI_VERSION/client64 > /etc/ld.so.conf.d/oracle-instantclient"
  sudo sh -c "echo instantclient,/usr/lib/oracle/$OCI_VERSION/client64/lib | pecl install oci8"
  sudo chcon system_u:object_r:textrel_shlib_t:s0 /usr/lib64/php/modules/oci8.so
  sudo chmod +x /usr/lib64/php/modules/oci8.so
  sudo sh -c 'echo extension=oci8.so > /etc/php.d/oci8.ini'
  sudo apachectl restart

  # PDO_OCI
  sudo mkdir -p /tmp/pear/download/
  cd /tmp/pear/download/
  sudo pecl download pdo_oci
  sudo tar xvf PDO_OCI-*.tgz
  cd PDO_OCI-*
  sudo curl -o config.m4 $OCI_CONFIG_URL
  sudo sed -i -e 's/function_entry pdo_oci_functions/zend_function_entry pdo_oci_functions/' pdo_oci.c
  sudo ln -s /usr/include/oracle/$OCI_VERSION/client64 /usr/include/oracle/$OCI_VERSION/client
  sudo ln -s /usr/lib/oracle/$OCI_VERSION/client64 /usr/lib/oracle/$OCI_VERSION/client
  sudo phpize
  sudo ./configure --with-pdo-oci=instantclient,/usr,$OCI_VERSION
  sudo make
  sudo make install
  sudo chcon system_u:object_r:textrel_shlib_t:s0 /usr/lib64/php/modules/pdo_oci.so
  sudo sh -c 'echo extension=pdo_oci.so > /etc/php.d/pdo_oci.ini'
  sudo apachectl restart
  sudo setsebool -P httpd_can_network_relay=1
  sudo setsebool -P httpd_can_network_connect 1
fi

# secure MySQL
echo ' '
echo ------------------------------------------------------------
echo 'PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER!'
echo 'It is also recommended to remove anonymous user and test databases. Please run:'
echo '/usr/bin/mysql_secure_installation'
echo ' '

