#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_RECMAN" ]; then
  source /vagrant/ubuntu.conf
fi

# RecordManager
echo "Installing RecordManager..."
echo "==========================="
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

# install RecordManager
sudo mkdir -p $RECMAN_PATH
cd $RECMAN_PATH
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
