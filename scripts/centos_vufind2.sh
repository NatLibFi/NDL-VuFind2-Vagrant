#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_VUFIND2" ]; then
  source /vagrant/centos.conf
fi
echo
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
      sudo cp $x $t
    fi
  done
done
cd $VUFIND2_PATH/local/config/vufind
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      sudo cp $x $t
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

# fix DB user password
if [[ "$SQL_USER_PW" != 'vufind' ]]; then
  sudo sed -i -e 's,mysql://vufind:vufind,mysql://vufind:'"$SQL_USER_PW"',' $VUFIND2_PATH/local/config/finna/config.ini
fi

# install MariaDB
#sudo yum -y install mariadb-server mariadb-libs mariadb
# fix MariaDB 'key was too long', see: https://dba.stackexchange.com/questions/231219/mariadb-10-1-38-specified-key-was-too-long-max-key-length-is-767-bytes
#sudo sed -i -e '/^\[mysqld\]/a innodb_file_format = Barracuda\ninnodb_file_per_table = on\ninnodb_large_prefix = 1\ninnodb_file_format_max = Barracuda' /etc/my.cnf
#sudo sed -i -e 's,json DEFAULT,longtext DEFAULT,' $VUFIND2_PATH/module/Finna/sql/mysql.sql
#sudo sed -i -e 's,timestamp NOT NULL,datetime NOT NULL,' $VUFIND2_PATH/module/Finna/sql/mysql.sql

# install MySQL
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo wget https://repo.mysql.com/mysql80-community-release-el7.rpm
sudo rpm -ivh mysql80-community-release-el7.rpm
sudo yum -y install mysql-server
sudo systemctl start mysqld
# change database root password
mysqladmin --user=root --password=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $13}') password $SQL_ROOT_PW

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="CREATE USER '$SQL_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$SQL_USER_PW';"
Q3="GRANT ALL ON $DATABASE.* TO '$SQL_USER'@'localhost';"
Q4="FLUSH PRIVILEGES;"
Q5="USE $DATABASE;"
Q6="SOURCE $VUFIND2_PATH/module/VuFind/sql/mysql.sql;"
Q7="SOURCE $VUFIND2_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}"
$MYSQL -uroot -p$SQL_ROOT_PW -e "$SQL"

# start MySQL at boot
sudo systemctl enable mysqld

# set security settings for Apache
#sudo chcon -R unconfined_u:object_r:httpd_sys_content_t:s0 /usr/local/vufind2/

# link VuFind2 to Apache
sudo chcon system_u:object_r:httpd_config_t:s0 /usr/local/vufind2/local/httpd-vufind.conf
# needed for e.g. 3D-files
sudo tee -a /usr/local/vufind2/local/httpd-vufind.conf > /dev/null <<EOT

# Configuration for public cache (used for asset pipeline minification)
AliasMatch ^/vufind2/cache/(.*)$ /vufind2/local/cache/public/$1
<Directory ~ "^/vufind2/local/cache/public/">
  <IfModule !mod_authz_core.c>
    Order allow,deny
    Allow from all
  </IfModule>
  <IfModule mod_authz_core.c>
    Require all granted
  </IfModule>
  AllowOverride All
</Directory>
EOT
if [ ! -h /etc/httpd/conf.d/vufind2.conf ]; then
  sudo ln -s /usr/local/vufind2/local/httpd-vufind.conf /etc/httpd/conf.d/vufind2.conf
fi

# install node.js & less 2.7.1 + less-plugin-clean-css
# https://github.com/nodesource/distributions
curl -fsSL https://rpm.nodesource.com/setup_$NODE_VERSION.x | sudo bash -
#add key
rpm --import https://rpm.nodesource.com/pub/el/NODESOURCE-GPG-SIGNING-KEY-EL
sudo yum -y install nodejs
# do not run these with sudo
npm install -g less@$LESS_VERSION
npm install -g less-plugin-clean-css
tee -a /usr/local/bin/less2css >/dev/null <<EOF
#!/usr/bin/env bash
sudo su -c 'lessc --clean-css="$LESS_CLEAN_CSS_OPTIONS" $VUFIND2_PATH/themes/finna2/less/finna.less > $VUFIND2_PATH/themes/finna2/css/finna.css'
if [ -f $VUFIND_PATH/themes/custom/less/finna.less ]; then
  sudo su -c 'lessc --clean-css="$LESS_CLEAN_CSS_OPTIONS" $VUFIND2_PATH/themes/custom/less/finna.less > $VUFIND2_PATH/themes/custom/css/finna.css'
fi
EOF
sudo chmod a+x /usr/local/bin/less2css
if [ "$LESS_RUN" = true ]; then  
  /usr/local/bin/less2css
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
cd $VUFIND2_PATH
sudo curl -sS https://getcomposer.org/composer-$COMPOSER_VERSION.phar --output /usr/local/bin/composer
sudo chmod a+x /usr/local/bin/composer
sudo /usr/local/bin/composer install --no-plugins --no-scripts
cd

# download datasources translation strings
curl $DATASOURCE_FI_URL > $VUFIND2_PATH/local/languages/finna/fi-datasources.ini
curl $DATASOURCE_SV_URL > $VUFIND2_PATH/local/languages/finna/sv-datasources.ini
curl $DATASOURCE_EN_URL > $VUFIND2_PATH/local/languages/finna/en-gb-datasources.ini

#Organisation if set
if [ ! -z "$DEFAULT_ORG" ]; then
  echo "
[General]
enabled = 1
defaultOrganisation = \"$DEFAULT_ORG\"
  
[OrganisationPage]" | sudo tee -a $VUFIND2_PATH/local/config/vufind/OrganisationInfo.ini > /dev/null
  if [ "$CONSORTIUM_INFO" = true ]; then
    sudo su -c 'echo consortiumInfo = 1 >> '"$VUFIND2_PATH"'/local/config/vufind/OrganisationInfo.ini'
  else
    sudo su -c 'echo consortiumInfo = 0 >> '"$VUFIND2_PATH"'/local/config/vufind/OrganisationInfo.ini'
  fi
fi

echo
echo "==============================="
echo "...done installing NDL-VuFind2."
