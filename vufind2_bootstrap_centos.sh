#!/bin/bash

# VuFind2 'install path' ie. mount path of the host's shared folder
INSTALL_PATH='/usr/local/vufind2'

# use single quotes instead of double quotes to make it work with special-character passwords
GITHUB_USER='NatLibFi'
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'

# turn SELinux on
sudo setenforce 1

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

# secure MySQL
echo
echo "PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER!"
echo "It is also recommended to remove anonymous user and test databases. Please run:"
echo "/usr/bin/mysql_secure_installation"
echo

