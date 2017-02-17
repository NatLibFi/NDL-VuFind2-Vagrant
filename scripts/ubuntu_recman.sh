#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_RECMAN" ]; then
  source /vagrant/ubuntu.conf
fi

# RecordManager
echo "Installing RecordManager..."
echo "==========================="
sudo apt-get install -y pkg-config libpcre3-dev phpunit

# libgeos and PHP bindings 
if [ "$INSTALL_GEOS" = true ]; then
  sudo apt-get install -y libgeos-3.5.0 libgeos-dev
  cd /tmp
  sudo git clone https://git.osgeo.org/gogs/geos/php-geos.git
  cd php-geos
  sudo ./autogen.sh
  sudo ./configure
  sudo make
  sudo make install
  sudo sh -c 'echo extension=geos.so > /etc/php/7.0/mods-available/geos.ini'
  sudo phpenmod geos
fi

# MongoDB driver
sudo sh -c 'echo no | sudo pecl install mongodb'
sudo sh -c 'echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`'
sudo service apache2 reload
sudo pear channel-update pear.php.net
sudo pear install HTTP_Request2
# MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo service mongod start

# install RecordManager
sudo mkdir -p $RECMAN_PATH
cd $RECMAN_PATH
sudo git clone $RECMAN_GIT --branch $RECMAN_BRANCH --single-branch $RECMAN_PATH
# run Composer
sudo /usr/local/bin/composer install --no-plugins --no-scripts
# connect to MongoDB
mongo recman dbscripts/mongo.js
# copy some sample configurations
sudo cp conf/abbreviations.lst.sample conf/abbreviations.lst
sudo cp conf/articles.lst.sample conf/articles.lst
sudo cp conf/recordmanager.ini.sample conf/recordmanager.ini
# modify settings
sudo sed -i -e 's,http://localhost:8080/solr/biblio/update/json,http://localhost:8983/solr/biblio/update,' conf/recordmanager.ini
sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = category_str_mv' conf/recordmanager.ini
sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = sector_str_mv' conf/recordmanager.ini
sudo sed -i '/;hierarchical_facets\[\] = building/a hierarchical_facets[] = format' conf/recordmanager.ini
sudo sed -i -e 's,;hierarchical_facets\[\] = building,hierarchical_facets[] = building,' conf/recordmanager.ini

# just a sample config - for actual use replace this with a proper one
#  sudo cat <<EOF >> conf/datasources.ini
sudo tee -a conf/datasources.ini >/dev/null <<EOF
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
echo "================================="
echo "...done installing RecordManager."
