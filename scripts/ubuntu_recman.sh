#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_RECMAN" ]; then
  source /vagrant/ubuntu.conf
fi

# RecordManager
echo
echo "Installing RecordManager..."
echo "==========================="
#sudo apt-get install -y pkg-config libpcre3-dev phpunit

# libgeos and PHP bindings 
if [ "$INSTALL_GEOS" = true ] && [ "$PHP_VERSION" == "7.4" ]; then
  sudo apt-get install -y libgeos-$LIBGEOS_VERSION libgeos-dev
  sudo apt-get install -y php-geos
  sudo phpenmod geos
fi

# MongoDB driver
sudo pecl channel-update pecl.php.net
sudo sh -c 'echo no | sudo pecl install mongodb'
sudo sh -c 'echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`'
sudo service apache2 reload
sudo pear channel-update pear.php.net
sudo pear install HTTP_Request2
# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-$MONGODB_VERSION.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-$MONGODB_VERSION.asc
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/$MONGODB_VERSION multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
# start at boot
sudo systemctl enable mongod

# install RecordManager
if [ "$RECMAN_DEV" = true ]; then
  cd $RECMAN_MOUNT
else
  sudo mkdir -p $RECMAN_PATH
  cd $RECMAN_PATH
  if [[ "$RECMAN_BRANCH" == "master" ]]; then
    sudo git clone $RECMAN_GIT $RECMAN_PATH
  else
    sudo git clone $RECMAN_GIT --branch $RECMAN_BRANCH --single-branch $RECMAN_PATH
  fi
fi
# run Composer
sudo /usr/local/bin/composer install --no-plugins --no-scripts
# connect to MongoDB
mongosh recman dbscripts/mongo.js
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
# fix UNIX socket URL encoding
sudo sed -i -e 's,mongodb:///tmp/,mongodb://%2Ftmp%2F,' conf/recordmanager.ini

# import data and load records into Solr
if [ "$RECMAN_IMPORT" = true ]; then
  if [[ "$RECMAN_SOURCE" == 'sample' ]]; then
    sudo cp /vagrant/data/sample_datasources.ini conf/datasources.ini
    sudo php import.php --file=/vagrant/data/sample_data.xml --source=sample
  else
    sudo cp $RECMAN_DATASOURCE conf/datasources.ini
    sudo php import.php --file=$RECMAN_DATA --source=$RECMAN_SOURCE
  fi
  sudo php manage.php --func=updatesolr 
fi
echo
echo "================================="
echo "...done installing RecordManager."
