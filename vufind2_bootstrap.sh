#!/usr/bin/env bash

# VuFind2 'install path' ie. mount path of the host's shared folder
INSTALL_PATH='/usr/local/vufind2'

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'
#PROJECTFOLDER='myproject'

# create project folder
#sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2.5 and php 5.5
sudo apt-get install -y apache2

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE $DATABASE;"
Q2="CREATE USER '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USER'@'localhost';"
Q4="FLUSH PRIVILEGES;"
Q5="USE $DATABASE;"
Q6="SOURCE $INSTALL_PATH/module/VuFind/sql/mysql.sql;"
Q7="SOURCE $INSTALL_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# install php 5.5
sudo apt-get install -y php5 php5-dev php-pear php5-json php5-mcrypt php5-mysql php5-xsl php5-intl php5-gd

# install Java JDK
sudo apt-get -y install default-jdk

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
#sudo apt-get -y install phpmyadmin

# setup hosts file
#VHOST=$(cat <<EOF
#<VirtualHost *:80>
#    DocumentRoot "/var/www/html/${PROJECTFOLDER}"
#    <Directory "/var/www/html/${PROJECTFOLDER}">
#        AllowOverride All
#        Require all granted
#    </Directory>
#</VirtualHost>
#EOF
#)
#echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# link VuFind to Apache
sudo cp /vagrant/httpd-vufind.conf /etc/apache2/conf-available/httpd-vufind.conf
sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf

# restart apache
service apache2 restart

# copy local dir inside virtual machine
sudo mkdir /usr/local/vufind2_local
sudo cp -rf $INSTALL_PATH/local/* /usr/local/vufind2_local/
sudo chown -R vagrant:vagrant /usr/local/vufind2_local
sudo chown -R www-data:www-data /usr/local/vufind2_local/cache

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# install git
#sudo apt-get -y install git

# install Composer
#curl -s https://getcomposer.org/installer | php
#mv composer.phar /usr/local/bin/composer
