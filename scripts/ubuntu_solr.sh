#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_SOLR" ]; then
  source /vagrant/ubuntu.conf
fi

# Solr
echo "Installing Solr..."
echo "=================="
# libvoikko
sudo apt-get install -y libvoikko-dev
sudo ldconfig
sudo mkdir -p /tmp/libvoikko
cd /tmp/libvoikko
sudo wget http://www.puimula.org/htp/testing/voikko-snapshot/dict.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-laaketiede.zip http://www.puimula.org/htp/testing/voikko-snapshot/dict-morphoid.zip
sudo unzip -d /etc/voikko '*.zip'

# add Java 8 repository; Solr 6 requires Java 8
sudo apt-add-repository -y ppa:webupd8team/java
sudo apt-get -q update

# install Java JDK
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

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
echo "========================"
echo "...done installing Solr."
