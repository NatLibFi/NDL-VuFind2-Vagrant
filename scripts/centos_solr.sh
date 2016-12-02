#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_SOLR" ]; then
  source /vagrant/centos.conf
fi

# Solr
echo "Installing Solr..."
echo "=================="

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

# install java
sudo yum -y install java-*-openjdk-devel

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
sudo yum -y install policycoreutils-python
sudo semanage port -a -t http_port_t -p tcp 8983
# start at boot
sudo chkconfig --add solr
sudo chkconfig solr on
echo "========================"
echo "...done installing Solr."
