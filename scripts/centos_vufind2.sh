#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_VUFIND2" ]; then
  source /vagrant/centos.conf
fi

echo "Installing NDL-VuFind2..."
echo "========================="

# install git & clone repository
sudo yum -y install git
sudo mkdir -p $VUFIND2_PATH
if [[ "$VUFIND2_BRANCH" == "master" ]]; then
  sudo git clone $VUFIND2_GIT $VUFIND2_PATH
  # if you want to be prompted for password, use the line below instead
  # sudo git clone https://$GITHUB_USER@github.com/$GITHUB_USER/NDL-VuFind2.git $VUFIND2_PATH
else
  sudo git clone $VUFIND2_GIT --branch $VUFIND2_BRANCH --single-branch $VUFIND2_PATH
  # if you want to be prompted for password, use the line below instead
  # sudo git clone https://$GITHUB_USER@github.com/$GITHUB_USER/NDL-VuFind2.git --branch $VUFIND2_BRANCH --single-branch $VUFIND2_PATH
fi

# set-up configuration files
cd $VUFIND2_PATH
sudo cp local/httpd-vufind.conf.sample local/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$VUFIND2_PATH"',' local/httpd-vufind.conf
CfgExt=( ini yaml json )
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

# modify MultiBackend default driver
sudo sed -i -e 's,default_driver = "NoILS",default_driver = "",' $VUFIND2_PATH/local/config/finna/MultiBackend.ini

# modify Solr URL if set
if [ ! -z "$EXTERNAL_SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *,url = '"$EXTERNAL_SOLR_URL"',' $VUFIND2_PATH/local/config/vufind/config.ini
fi

# install MariaDB
sudo yum -y install mariadb-server mariadb
sudo systemctl start mariadb

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $VUFIND2_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $VUFIND2_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -e "$SQL"

# start MariaDB at boot
sudo systemctl enable mariadb

# set security settings for Apache
#sudo chcon -R unconfined_u:object_r:httpd_sys_content_t:s0 /usr/local/vufind2/

# link VuFind2 to Apache
sudo chcon system_u:object_r:httpd_config_t:s0 /usr/local/vufind2/local/httpd-vufind.conf
if [ ! -h /etc/httpd/conf.d/vufind2.conf ]; then
  sudo ln -s /usr/local/vufind2/local/httpd-vufind.conf /etc/httpd/conf.d/vufind2.conf
fi

# give Apache permissions to use the cache and config
sudo chown -R apache:apache /usr/local/vufind2/local/cache/
sudo chcon -R unconfined_u:object_r:httpd_sys_rw_content_t:s0 /usr/local/vufind2/local/cache/
sudo chown -R apache:apache /usr/local/vufind2/local/config/
sudo chcon -R unconfined_u:object_r:httpd_sys_rw_content_t:s0 /usr/local/vufind2/local/config/

# create VuFind2 logfile
sudo touch /var/log/vufind2.log
sudo chown apache:apache /var/log/vufind2.log
sudo chcon unconfined_u:object_r:httpd_sys_rw_content_t:s0 /var/log/vufind2.log

# set environment variables (common for all users)
sudo su -c 'echo export VUFIND_HOME="/usr/local/vufind2"  > /etc/profile.d/vufind.sh'
sudo su -c 'echo export VUFIND_LOCAL_DIR="/usr/local/vufind2/local"  >> /etc/profile.d/vufind.sh'
sudo su -c 'source /etc/profile.d/vufind.sh'

# install Composer (globally)
cd /usr/local/vufind2
sudo curl -sS https://getcomposer.org/installer | sudo php
sudo mv composer.phar /usr/local/bin/composer
sudo /usr/local/bin/composer install --no-plugins --no-scripts
cd

echo "==============================="
echo "...done installing NDL-VuFind2."
