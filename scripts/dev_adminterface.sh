#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_ADMINTERFACE" ]; then
  source /vagrant/dev.conf
fi
echo
echo "Installing AdminInterface..."
echo "============================"

# fix paths
sudo mkdir /data
sudo ln -s $ADMINTERFACE_MOUNT $ADMINTERFACE_DEFAULT_PATH
sudo ln -s $VUFIND2_MOUNT /data/vufind2-base
# log files
sudo touch /var/log/php_errors.log
sudo chown www-data:www-data /var/log/php_errors.log
sudo mkdir -p $ADMINTERFACE_LOG_PATH
touch $ADMINTERFACE_LOG_PATH/admininterface.log
touch $ADMINTERFACE_LOG_PATH/admininterface-actions.log
touch $ADMINTERFACE_LOG_PATH/admininterface-triggers.log
touch $ADMINTERFACE_LOG_PATH/admininterface-console.log
touch $ADMINTERFACE_LOG_PATH/admininterface-moderation.log
touch $ADMINTERFACE_LOG_PATH/admininterface-forms.log
touch $ADMINTERFACE_LOG_PATH/admininterface-statistics-report.log
touch $ADMINTERFACE_LOG_PATH/admininterface-publisher.log
sudo chmod g+w $ADMINTERFACE_LOG_PATH/*
sudo chown vagrant:www-data $ADMINTERFACE_LOG_PATH/
sudo chown vagrant:www-data $ADMINTERFACE_LOG_PATH/*

# configure Apache
sudo ln -s $ADMINTERFACE_MOUNT/config/apache/admininterface.conf /etc/apache2/conf-enabled/
sudo mkdir -p $ADMINTERFACE_MOUNT/data/DoctrineORMModule/Proxy $ADMINTERFACE_MOUNT/local/cache/public
sudo chmod g+w $ADMINTERFACE_MOUNT/data/DoctrineORMModule/Proxy $ADMINTERFACE_MOUNT/local/cache/public
sudo mkdir -p /data/vufind2-views/
sudo chown -R vagrant:www-data /data/vufind2-views/
sudo chmod g+w /data/vufind2-views/
# restart Apache
sudo service apache2 reload

cp $ADMINTERFACE_MOUNT/.env.sample $ADMINTERFACE_MOUNT/.env
cp $ADMINTERFACE_MOUNT/config/vufind/adminInterface.ini $ADMINTERFACE_MOUNT/local/config/vufind/

cd $ADMINTERFACE_MOUNT
if [ "$INSTALL_VUFIND2" = false ]; then
  # install Composer (globally) - see: https://github.com/Varying-Vagrant-Vagrants/VVV/issues/986
  sudo curl -sS https://getcomposer.org/composer-$COMPOSER_VERSION.phar --output /usr/local/bin/composer
  sudo chmod a+x /usr/local/bin/composer
fi
# install Composer packages
sudo su vagrant -c '/usr/local/bin/composer install --no-plugins --no-scripts'

if [ "$INSTALL_VUFIND2" = false ]; then
  # install node.js & less + less-plugin-clean-css + eslint
  export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt-get update
  sudo apt-get install -y nodejs
  sudo npm install -g less@$LESS_VERSION
  sudo npm install -g less-plugin-clean-css
  sudo npm install -g eslint@$ESLINT_VERSION
  #check npm vulnerabilities
  npm init -y
  npm i
  npm audit
fi
npm run dev

if [ "$INSTALL_VUFIND2" = false ]; then
  # install MariaDB and give password to installer
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
  sudo apt-get -y install mariadb-server
  # fix mysqld options errors
  sudo sed -i -e '0,/key_buffer\t/s//key_buffer_size\t/' /etc/mysql/my.cnf
  sudo sed -i -e 's/myisam-recover\s\{2,\}/myisam-recover-options\t/' /etc/mysql/my.cnf
fi

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $ADMINT_DATABASE;"
Q2="CREATE DATABASE IF NOT EXISTS admininterface3_test;"
Q3="CREATE USER '$ADMINT_SQL_USER'@'localhost' IDENTIFIED BY '$ADMINT_SQL_USER_PW';"
Q4="GRANT ALL ON $ADMINT_DATABASE.* TO '$ADMINT_SQL_USER'@'localhost';"
Q5="GRANT ALL ON admininterface3_test.* TO '$ADMINT_SQL_USER'@'localhost';"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# Doctrine - contains tables and test data for the database
$ADMINTERFACE_MOUNT/console doctrine-module migrations:migrate --allow-no-migration --no-interaction
$ADMINTERFACE_MOUNT/console doctrine-module data-fixture:import statuses
$ADMINTERFACE_MOUNT/console doctrine-module data-fixture:import institutions
$ADMINTERFACE_MOUNT/console doctrine-module data-fixture:import users
cd

# Crontab
crontab $ADMINTERFACE_MOUNT/config/crontab/admininterface
# localhost
sudo sed -i -e 's,127.0.0.1 localhost,127.0.0.1 localhost ai.finna.local analytics.finna.local finna.local test.finna.local,' /etc/hosts

echo
echo "=================================="
echo "...done installing AdminInterface."
