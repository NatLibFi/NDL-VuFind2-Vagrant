#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
[[ $INSTALL_SOLR ]]
{
  source /vagrant/centos.conf
  # make sure these get installed
  INSTALL_SOLR=true
  INSTALL_RM=true
}

# Solr
if [ "$INSTALL_SOLR" = true ]; then
  echo "Installing Solr..."
  # libvoikko
  cd /etc/yum.repos.d
  sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo
  sudo yum -y install malaga gcc gcc-c++ apache-maven unzip lsof
  sudo mkdir /tmp/libvoikko
  cd /tmp/libvoikko
  # maybe check for a new version from time to time and keep this updated?
  sudo wget http://www.puimula.org/voikko-sources/libvoikko/libvoikko-3.8.tar.gz
  sudo tar -xzf libvoikko-3.8.tar.gz
  cd libvoikko-3.8
  sudo ./configure
  sudo make
  sudo make install
  sudo ln -s /usr/local/lib/libvoikko.so.1.* /usr/lib/libvoikko.so.1
  sudo ldconfig
  cd ..
  sudo wget http://www.puimula.org/htp/testing/voikko-snapshot/dict.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-laaketiede.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-morphoid.zip
  sudo unzip -d /etc/voikko '*.zip'

  # install Solr
  sudo mkdir -p $SOLR_PATH
  sudo git clone https://github.com/NatLibFi/NDL-VuFind-Solr.git $SOLR_PATH
  sudo cp $SOLR_PATH/vufind/solr.in.finna.sh.sample $SOLR_PATH/vufind/solr.in.finna.sh
  sudo adduser solr
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
  sudo semanage port -a -t http_port_t -p tcp 8983
  # start at boot
  sudo chkconfig --add solr
  sudo chkconfig solr on
  echo "...done installing Solr."
fi

# RecordManager
if [ "$INSTALL_RM" = true ]; then
  echo "Installing RecordManager..."
  sudo yum -y install openssl-devel policycoreutils-python
  sudo sh -c 'echo no | sudo pecl install mongo'
  sudo sh -c 'echo extension=mongo.so > /etc/php.d/mongo.ini'
  sudo service httpd reload
  sudo pear channel-update pear.php.net
  sudo pear install HTTP_Request2
  # MongoDB
  sudo wget -O /etc/yum.repos.d/mongodb-org.repo https://repo.mongodb.org/yum/redhat/mongodb-org.repo
  sudo yum install -y mongodb-org
  sudo semanage port -a -t mongod_port_t -p tcp 27017
  sudo service mongod start
  # start at boot
  sudo chkconfig mongod on

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
echo "...done installing RecordManager."
fi
