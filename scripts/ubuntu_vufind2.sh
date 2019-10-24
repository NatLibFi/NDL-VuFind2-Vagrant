#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_VUFIND2" ]; then
  source /vagrant/ubuntu.conf
fi
echo
echo "Installing NDL-VuFind2..."
echo "========================="

# install MySQL and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
# fix mysqld options errors
sudo sed -i -e '0,/key_buffer\t/s//key_buffer_size\t/' /etc/mysql/my.cnf
sudo sed -i -e 's/myisam-recover\s\{2,\}/myisam-recover-options\t/' /etc/mysql/my.cnf

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$SQL_USER'@'localhost' IDENTIFIED BY '$SQL_USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $VUFIND2_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $VUFIND2_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

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

# modify MultiBackend default driver
sudo sed -i -e 's,default_driver = "NoILS",default_driver = "",' $VUFIND2_PATH/local/config/finna/MultiBackend.ini

# modify Solr URL if set
if [ ! -z "$EXTERNAL_SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *,url = '"$EXTERNAL_SOLR_URL"',' $VUFIND2_PATH/local/config/vufind/config.ini
fi

# install Composer (globally) - see: https://github.com/Varying-Vagrant-Vagrants/VVV/issues/986
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
cd $VUFIND2_PATH
/usr/local/bin/composer install --no-plugins --no-scripts
cd

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# install node.js & less 2.7.1 + less-plugin-clean-css
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"
curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g less@$LESS_VERSION
sudo npm install -g less-plugin-clean-css
# do not run these with sudo
tee -a /usr/local/bin/less2css >/dev/null <<EOF
#!/usr/bin/env bash
lessc --clean-css="$LESS_CLEAN_CSS_OPTIONS" $VUFIND2_PATH/themes/finna2/less/finna.less > $VUFIND2_PATH/themes/finna2/css/finna.css
if [ -f $VUFIND_PATH/themes/custom/less/finna.less ]; then
  lessc --clean-css="$LESS_CLEAN_CSS_OPTIONS" $VUFIND2_PATH/themes/custom/less/finna.less > $VUFIND2_PATH/themes/custom/css/finna.css
fi
EOF
sudo chmod a+x /usr/local/bin/less2css
if [ "$LESS_RUN" = true ]; then
  /usr/local/bin/less2css
fi

# download datasources translation strings
curl 'https://www.finna-test.fi/fi-datasources.ini' > $VUFIND2_PATH/local/languages/finna/fi-datasources.ini
curl 'https://www.finna-test.fi/sv-datasources.ini' > $VUFIND2_PATH/local/languages/finna/sv-datasources.ini
curl 'https://www.finna-test.fi/en-gb-datasources.ini' > $VUFIND2_PATH/local/languages/finna/en-gb-datasources.ini

echo
echo "==============================="
echo "...done installing NDL-VuFind2."
