#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_VUFIND2" ]; then
  source /vagrant/dev.conf
fi
echo
echo "Installing NDL-VuFind2..."
echo "========================="

# install MariaDB and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mariadb-server
# fix mysqld options errors
sudo sed -i -e '0,/key_buffer\t/s//key_buffer_size\t/' /etc/mysql/my.cnf
sudo sed -i -e 's/myisam-recover\s\{2,\}/myisam-recover-options\t/' /etc/mysql/my.cnf

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="CREATE USER '$SQL_USER'@'localhost' IDENTIFIED BY '$SQL_USER_PW';"
Q3="GRANT ALL ON $DATABASE.* TO '$SQL_USER'@'localhost';"
Q4="FLUSH PRIVILEGES;"
Q5="USE $DATABASE;"
Q6="SOURCE $VUFIND2_MOUNT/module/VuFind/sql/mysql.sql;"
Q7="SOURCE $VUFIND2_MOUNT/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# link VuFind to Apache
sudo cp -f $VUFIND2_MOUNT/local/httpd-vufind.conf.sample /etc/apache2/conf-available/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$VUFIND2_MOUNT"',' /etc/apache2/conf-available/httpd-vufind.conf

# needed for e.g. 3D-files
sudo tee -a /etc/apache2/conf-available/httpd-vufind.conf > /dev/null <<EOT
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
if [ ! -h /etc/apache2/conf-enabled/vufind2.conf ]; then
  sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf
fi

# If rsyncing make sure the web server has cache with permissions
if [ "$RSYNC" = true ]; then
  sudo mkdir /vufind2/local/cache
  sudo chown www-data:www-data /vufind2/local/cache
fi

# config file extensions
CfgExt=( ini yaml json )

# copy sample configs to ini files
cd $VUFIND2_MOUNT/local/config/finna
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      cp $x $t
    fi
  done
done

cd $VUFIND2_MOUNT/local/config/vufind
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
sudo sed -i -e 's,default_driver = "NoILS",default_driver = "",' $VUFIND2_MOUNT/local/config/finna/MultiBackend.ini

# modify Solr URL if set
if [ ! -z "$EXTERNAL_SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *,url = '"$EXTERNAL_SOLR_URL"',' $VUFIND2_MOUNT/local/config/vufind/config.ini
fi

# install Composer (globally) - see: https://github.com/Varying-Vagrant-Vagrants/VVV/issues/986
sudo curl -sS https://getcomposer.org/composer-$COMPOSER_VERSION.phar --output /usr/local/bin/composer
sudo chmod a+x /usr/local/bin/composer
cd $VUFIND2_MOUNT
sudo su vagrant -c '/usr/local/bin/composer install --no-plugins --no-scripts'

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# install node.js & less 2.7.1 + less-plugin-clean-css
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install -y nodejs
# do not run this with sudo
npm install
#check npm vulnerabilities
npm audit

# phing: do not run this with sudo
tee -a /usr/local/bin/phing >/dev/null <<EOF
#!/usr/bin/env bash
cd $VUFIND2_MOUNT
vendor/phing/phing/bin/phing $PHING_VARS
EOF
sudo chmod a+x /usr/local/bin/phing

# build-css: do not run this with sudo
tee -a /usr/local/bin/build-scss >/dev/null <<EOF
#!/usr/bin/env bash
cd $VUFIND2_MOUNT
npm run finna:build:scss
cd
EOF
sudo chmod a+x /usr/local/bin/build-scss
if [ "$SCSS_BUILD" = true ]; then
  /usr/local/bin/build-scss
fi

# download datasources translation strings
for i in "${DATASOURCES[@]}"; do
  curl $DATASOURCES_URL/$i-datasources.ini > $VUFIND2_MOUNT/local/languages/finna/$i-datasources.ini
done

# organisation if set
if [ ! -z "$DEFAULT_ORG" ]; then
  if ! grep -Fxq -m 1 [General] $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini; then
    tee -a $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini >/dev/null <<EOF

[General]
enabled = 1
defaultOrganisation = "$DEFAULT_ORG"
EOF
  else
    sudo sed -E -i 's,enabled.+,enabled = 1,' $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini
    sudo sed -E -i 's,defaultOrganisation.+,defaultOrganisation = "'$DEFAULT_ORG'",' $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini
  fi
elif grep -Fxq -m 1 [General] $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini; then
  sudo sed -i -e '/General/{N;N;N;d}' $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini
fi

# consortiuminfo if set
if [ "$CONSORTIUM_INFO" = true ]; then
  if ! grep -Fxq -m 1 [OrganisationPage] $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini; then 
    tee -a $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini >/dev/null <<EOF

[OrganisationPage]
consortiumInfo = 1
EOF
  else 
    sudo sed -i -E 's,consortiumInfo.+,consortiumInfo = 1,' $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini
  fi
else 
  sudo sed -i -E 's,consortiumInfo.+,consortiumInfo = 0,' $VUFIND2_MOUNT/local/config/vufind/OrganisationInfo.ini
fi

# prepare for unit-tests
tee -a /home/vagrant/phing.sh >/dev/null <<EOF
#!/bin/sh
$VUFIND2_MOUNT/vendor/bin/phing -Dmysqlrootpass=$PASSWORD \$*
EOF
sudo chmod a+x /home/vagrant/phing.sh
cp $VUFIND2_MOUNT/build.xml /home/vagrant/
sudo sed -i -e 's,basedir=".",basedir="/vufind2",' /home/vagrant/build.xml

# set up email test environment
if [ "$EMAIL_TEST_ENV" = true ]; then
  cd /home/vagrant
  sudo su vagrant -c 'mkdir -p finna-views/testi'
  sudo su vagrant -c 'mkdir -p finna-views/127'
  ln -s $VUFIND2_MOUNT finna-views/testi/default
  ln -s $VUFIND2_MOUNT finna-views/127$VUFIND2_MOUNT
  # add write permission to log
  sudo chmod o+w /var/log/vufind2.log
  # create script file for due date reminder
  # run with:
  # $ vagrant ssh -c "duedatereminder"
  tee -a /usr/local/bin/due_date_reminders >/dev/null <<EOF
#!/usr/bin/env bash
VUFIND_LOCAL_MODULES=FinnaSearch,FinnaTheme,Finna,FinnaConsole VUFIND_LOCAL_DIR=$VUFIND2_MOUNT/local php -d short_open_tag=1 $VUFIND2_MOUNT/public/index.php util due_date_reminders $VUFIND2_MOUNT /home/vagrant/finna-views
EOF
  sudo chmod a+x /usr/local/bin/due_date_reminders
  # create script file for scheduled alert
  # run with:
  # $ vagrant ssh -c "scheduledalert"
  tee -a /usr/local/bin/scheduled_alerts >/dev/null <<EOF
#!/usr/bin/env bash
VUFIND_LOCAL_MODULES=FinnaSearch,FinnaTheme,Finna,FinnaConsole VUFIND_LOCAL_DIR=$VUFIND2_MOUNT/local php -d short_open_tag=1 $VUFIND2_MOUNT/public/index.php util scheduled_alerts /home/vagrant/finna-views $VUFIND2_MOUNT/local
EOF
  sudo chmod a+x /usr/local/bin/scheduled_alerts
fi

# clear VuFind2 local cache files
# see: https://askubuntu.com/questions/266179/how-to-exclude-ignore-hidden-files-and-directories-in-a-wildcard-embedded-find
if [ "$LOCAL_CACHE_CLEAR" = true ]; then
  echo "Clearing VuFind2 local cache..."
  find $VUFIND2_MOUNT/local/cache/ \( ! -regex '.*/\..*' \) -type f -name "*" -delete
  echo "...done!"
fi

echo
echo "==============================="
echo "...done installing NDL-VuFind2."
