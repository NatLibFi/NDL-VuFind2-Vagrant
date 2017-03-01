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
sudo yum -y install php70w-pecl-mongodb
sudo sh -c 'printf "extension=mongodb.so\n" >> /etc/php.d/mongodb.ini'
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
