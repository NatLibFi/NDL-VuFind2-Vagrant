#!/usr/bin/env bash

#########################  C O N F I G U R A T I O N  #########################
# Use single quotes instead of double to work with special-character passwords

# VuFind2 'install path' ie. mount path/point of the host's shared folder
VUFIND2_PATH='/vufind2'

# MySQL
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'

# External index URL if not installing Solr + RecordManager locally.
EXTERNAL_SOLR_URL=''

# Oracle PHP OCI Instant Client (Voyager)
INSTALL_ORACLE_CLIENT=true         # Make sure you have the installer ZIP files
ORACLE_PATH='/vagrant/oracle'      # downloaded here from Oracle Downloads.
CONFIG_PATH='/vagrant/config'      # Voyager config files.
# version info
OCI_VERSION='12_1'
OCI_DOT_VERSION='12.1'
# versions above 12.1 need a new config file to be created
OCI_CONFIG_URL='http://pastebin.com/raw/20T49aHg'  # 20T49aHg <= v12.1

# Solr
INSTALL_SOLR=true                  # If true you will also need RecordManager!
SOLR_PATH='/data/solr'             # Separately installing one without the other
JAVA_HEAP_MIN='256m'               # is only useful for debugging the install
JAVA_HEAP_MAX='512m'               # process if errors arise.

# RecordManager
INSTALL_RM=true
RM_PATH='/usr/local/RecordManager'
SAMPLE_DATA='/vagrant/config/sample.xml'  # use MARC  

# timezone
TIMEZONE='Europe/Helsinki'

###############################################################################

# set timezone
sudo timedatectl set-timezone $TIMEZONE

# supress irrelevant stdin errors
sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# add Java 8 repository
sudo apt-add-repository -y ppa:webupd8team/java

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2
sudo apt-get install -y apache2

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
# fix mysqld options errors
sudo sed -i -e '0,/key_buffer\t/s//key_buffer_size\t/' /etc/mysql/my.cnf
sudo sed -i -e 's/myisam-recover\s\{2,\}/myisam-recover-options\t/' /etc/mysql/my.cnf

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $VUFIND2_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $VUFIND2_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# install php 5
sudo apt-get install -y php5 php5-dev php-pear php5-json php5-mcrypt php5-mysql php5-xsl php5-intl php5-gd php5-curl

# change php.ini: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php5/apache2/php.ini

# install Java JDK. Solr 6 requires Java 8
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

# enable mod_rewrite & mod_headers
sudo a2enmod rewrite
sudo a2enmod headers

# link VuFind to Apache
sudo cp -f $VUFIND2_PATH/local/httpd-vufind.conf.sample /etc/apache2/conf-available/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$VUFIND2_PATH"',' /etc/apache2/conf-available/httpd-vufind.conf
if [ ! -h /etc/apache2/conf-enabled/vufind2.conf ]; then
  sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf
fi

# copy sample configs to ini files
cd $VUFIND2_PATH/local/config/finna
for x in *.ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done

cd $VUFIND2_PATH/local/config/vufind
for x in *ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done
cp searchspecs.yaml.sample searchspecs.yaml
cd

# modify Solr URL if set
if [ ! -z "$EXTERNAL_SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *,url = '"$EXTERNAL_SOLR_URL"',' $VUFIND2_PATH/local/config/vufind/config.ini
fi

# install Composer (globally)
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
cd /vufind2
sudo composer install
cd

# restart apache
service apache2 reload

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# Oracle PHP OCI driver
if [ "$INSTALL_ORACLE_CLIENT" = true ]; then
  ORACLE_FILES_EXIST=false
  for f in $ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip; do
    [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer ZIP files found!"
    break
  done
fi
if [ "$INSTALL_ORACLE_CLIENT" = true -a "$ORACLE_FILES_EXIST" = true ] ; then
  sudo pear upgrade pear
  mkdir -p /opt/oracle
  cd /opt/oracle
  sudo apt-get install -y unzip
  sudo unzip -o "$ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip" -d ./
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so.* /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libocci.so.* /opt/oracle/instantclient_$OCI_VERSION/libocci.so
  sudo sh -c "echo /opt/oracle/instantclient_$OCI_VERSION > /etc/ld.so.conf.d/oracle-instantclient"
  if php --version | grep -q "PHP 7"; then
    # oci8 2.1.0 and up needs php7
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8"
  else
    # use older version
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8-2.0.10"
  fi
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
    cp -rf $CONFIG_PATH/VoyagerRestful_*.ini $VUFIND2_PATH/local/config/vufind/
    for i in "${voyagers[@]}"; do
      org=$(echo $i| cut -d'_' -f 2| cut -d'.' -f 1)
      sed -i '/\[Drivers\]$/a '"$org"' = VoyagerRestful' $VUFIND2_PATH/local/config/finna/MultiBackend.ini
    done
  fi
fi

# Solr
if [ "$INSTALL_SOLR" = true ]; then
  # libvoikko
  sudo apt-get install -y libvoikko-dev
  sudo ldconfig
  sudo mkdir -p /tmp/libvoikko
  cd /tmp/libvoikko
  sudo wget http://www.puimula.org/htp/testing/voikko-snapshot/dict.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-laaketiede.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-morphoid.zip
  sudo unzip -d /etc/voikko '*.zip'

  # install Solr
  sudo mkdir -p $SOLR_PATH
  sudo apt-get install -y git
  sudo git clone https://github.com/NatLibFi/NDL-VuFind-Solr.git $SOLR_PATH
  sudo cp $SOLR_PATH/vufind/solr.in.finna.sh.sample $SOLR_PATH/vufind/solr.in.finna.sh
  sudo su -c "useradd solr -m"
  sudo su -c 'echo solr:rlos | chpasswd'
  sudo chown -R solr:solr $SOLR_PATH
  sudo cp $SOLR_PATH/vufind/solr.finna-init-script /etc/init.d/solr
  sudo cp $SOLR_PATH/vufind/biblio/core.properties.sample $SOLR_PATH/vufind/biblio/core.properties
  sudo chmod +x /etc/init.d/solr
  # set java heap min/max
  sudo sed -i 's/SOLR_JAVA_MEM=/#SOLR_JAVA_MEM=/' $SOLR_PATH/vufind/solr.in.finna.sh
  sudo sed -i '/#SOLR_JAVA_MEM/a SOLR_JAVA_MEM="-Xms'"$JAVA_HEAP_MIN"' -Xmx'"$JAVA_HEAP_MAX"'"' $SOLR_PATH/vufind/solr.in.finna.sh
  # fix solr local dir setting in vufind
  sudo sed -i '/;url *= */a local = '"$SOLR_PATH"'' $VUFIND2_PATH/local/config/vufind/config.ini
  sudo service solr start
  # start at boot
  sudo update-rc.d solr defaults
fi

# RecordManager
if [ "$INSTALL_RM" = true ]; then
#  sudo yum -y install openssl-devel policycoreutils-python
  sudo sh -c 'echo no | sudo pecl install mongo'
  sudo sh -c 'echo extension=mongo.so > /etc/php5/mods-available/mongo.ini'
  sudo php5enmod mongo
  sudo service apache2 reload
  sudo pear channel-update pear.php.net
  sudo pear install HTTP_Request2
  # MongoDB
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org

  # install RM
  sudo mkdir -p $RM_PATH
  cd $RM_PATH
  sudo git clone https://github.com/NatLibFi/RecordManager.git .
  mongo recman dbscripts/mongo.js
  sudo cp conf/abbreviations.lst.sample conf/abbreviations.lst
  sudo cp conf/articles.lst.sample conf/articles.lst
  sudo cp conf/recordmanager.ini.sample conf/recordmanager.ini
  sudo sed -i -e 's,http://localhost:8080/solr/biblio/update/json,http://localhost:8983/solr/biblio/update,' conf/recordmanager.ini
  sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = category_str_mv' conf/recordmanager.ini
  sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = sector_str_mv' conf/recordmanager.ini
  sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = format' conf/recordmanager.ini
  sudo sed -i -e 's,;hierarchical_facets\[\] = building,hierarchical_facets[] = building,' conf/recordmanager.ini

  # just a sample config - for actual use replace this with a proper one
  sudo cat <<EOF >> conf/datasources.ini
[sample]
institution = testituutio
recordXPath = "//record"
format = marc
EOF
  # import sample data and load records into Solr
  if [ -f "$SAMPLE_DATA" ]; then
    sudo php import.php --file=$SAMPLE_DATA --source=sample
    sudo php manage.php --func=updatesolr 
  fi
fi

