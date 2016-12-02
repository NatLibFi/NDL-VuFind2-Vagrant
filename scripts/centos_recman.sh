#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_RECMAN" ]; then
  source /vagrant/centos.conf
fi

# RecordManager
echo "Installing RecordManager..."
echo "==========================="
sudo yum -y install openssl-devel policycoreutils-python
sudo sh -c 'echo no | sudo pecl install mongo'
sudo sh -c 'echo extension=mongo.so > /etc/php.d/mongo.ini'
sudo service httpd reload
sudo pear channel-update pear.php.net
sudo pear install HTTP_Request2
# MongoDB
sudo wget -O /etc/yum.repos.d/mongodb-org.repo https://repo.mongodb.org/yum/redhat/mongodb-org.repo
sudo yum install -y mongodb-org
if yum list installed mongodb-org >/dev/null 2>&1; then
  echo "mongodb-org was installed properly."
else
  # at the moment the repo path is wrong so let's fix it (this will probably become moot later)
  sudo sed -i 's/stable/3.2/' /etc/yum.repos.d/mongodb-org.repo    
  echo "mongodb-org repo path fixed. Re-trying install..."
  sudo yum install -y mongodb-org
fi
sudo semanage port -a -t mongod_port_t -p tcp 27017
sudo service mongod start
# start at boot
sudo chkconfig mongod on

# install RM
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
