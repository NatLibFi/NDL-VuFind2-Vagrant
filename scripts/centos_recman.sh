#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_RECMAN" ]; then
  source /vagrant/centos.conf
fi

# RecordManager
echo "Installing RecordManager..."
echo "==========================="
sudo yum -y install openssl-devel

# libgeos; with PHP7 https://git.osgeo.org/gogs/geos/php-geos + geos-devel might be required
if [ "$INSTALL_GEOS" = true ]; then
  sudo yum -y install geos geos-php geos-devel
  cd /tmp
  sudo git clone https://git.osgeo.org/gogs/geos/php-geos.git
  cd php-geos
  sudo ./autogen.sh
  sudo ./configure
  sudo make
  sudo make install
fi

sudo pear channel-update pear.php.net
sudo pear install HTTP_Request2

#MongoDB driver
sudo yum -y install php-pecl-mongodb
#sudo sh -c 'printf "extension=mongodb.so\n" >> /etc/php.d/mongodb.ini'
sudo systemctl reload httpd
# MongoDB
sudo tee -a /etc/yum.repos.d/mongodb-org-3.4.repo >/dev/null <<EOF
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF
sudo rpm --import https://www.mongodb.org/static/pgp/server-3.4.asc
sudo yum -y update
sudo yum -y install mongodb-org
sudo semanage port -a -t mongod_port_t -p tcp 27017
sudo systemctl start mongod
# start at boot
sudo systemctl enable mongod

# install RecordManager
sudo mkdir -p $RECMAN_PATH
cd $RECMAN_PATH
if [[ "$RECMAN_BRANCH" == "master" ]]; then
  sudo git clone $RECMAN_GIT $RECMAN_PATH
else
  sudo git clone $RECMAN_GIT --branch $RECMAN_BRANCH --single-branch $RECMAN_PATH
fi
# run Composer
sudo /usr/local/bin/composer install --no-plugins --no-scripts
# create indexes
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
