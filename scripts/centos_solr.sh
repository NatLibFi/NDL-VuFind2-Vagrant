#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_SOLR" ]; then
  source /vagrant/centos.conf
fi
echo
echo "Installing Solr..."
echo "=================="
# libvoikko
sudo yum -y install libvoikko unzip wget
cd /tmp
sudo wget http://www.puimula.org/htp/testing/voikko-snapshot/dict-morphoid.zip
sudo unzip -d /etc/voikko '*.zip'

# install java
sudo yum -y install java-*-openjdk-devel

# install Solr
sudo mkdir -p $SOLR_PATH
if [[ "$SOLR_BRANCH" == "master" ]]; then
  sudo git clone $SOLR_GIT $SOLR_PATH
else
  sudo git clone $SOLR_GIT --branch $SOLR_BRANCH --single-branch $SOLR_PATH
fi
sudo adduser solr
#sudo su -c 'echo solr:rlos | chpasswd'
cd $SOLR_PATH
sudo ./install_solr.sh
sudo cp $SOLR_PATH/vufind/solr.in.finna.sh.sample $SOLR_PATH/vufind/solr.in.finna.sh
sudo cp $SOLR_PATH/vufind/biblio/core.properties.sample $SOLR_PATH/vufind/biblio/core.properties
sudo chown -R solr $SOLR_PATH

# set java heap min/max
sudo sed -i 's/SOLR_JAVA_MEM=/#SOLR_JAVA_MEM=/' $SOLR_PATH/vufind/solr.in.finna.sh
sudo sed -i '/#SOLR_JAVA_MEM/a SOLR_JAVA_MEM="-Xms'"$JAVA_HEAP_MIN"' -Xmx'"$JAVA_HEAP_MAX"'"' $SOLR_PATH/vufind/solr.in.finna.sh
# disable solrcloud
sudo sed -i 's/ZK_/#ZK_=/' $SOLR_PATH/vufind/solr.in.finna.sh
sudo sed -i 's/SOLR_MODE/#SOLR_MODE=/' $SOLR_PATH/vufind/solr.in.finna.sh

# fix solr local dir setting in vufind
sudo sed -i '/;url *= */a local = '"$SOLR_PATH"'' $VUFIND2_PATH/local/config/vufind/config.ini

sudo yum -y install policycoreutils-python lsof
sudo semanage port -a -t http_port_t -p tcp 8983

#set as service
sudo cp $SOLR_PATH/vufind/solr.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable solr
sudo systemctl start solr
echo
echo "========================"
echo "...done installing Solr."
