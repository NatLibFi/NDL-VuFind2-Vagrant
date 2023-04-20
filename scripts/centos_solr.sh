#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_SOLR" ]; then
  source /vagrant/centos.conf
fi

# Solr
echo
echo "Installing Solr..."
echo "=================="
# install Java OpenJDK
sudo yum -y install java-$JAVA_VERSION-openjdk-devel
# set memory & open files limit
if [ "$JAVA_SET_SHMMAX_OPENFILES" = true ]; then
    echo $JAVA_SHMMAX | sudo tee /proc/sys/kernel/shmmax
    echo -e "soft nofile $JAVA_OPENFILES_LIMIT\nhard nofile $JAVA_OPENFILES_LIMIT" | sudo tee -a /etc/sysctl.conf
fi

# Set used Java version
# TODO: Fix this properly later
#sudo sudo rm /etc/alternatives/java
#sudo ln -s /usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el8_7.x86_64/bin/java /etc/alternatives/java

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
sudo cp $SOLR_PATH/vufind/biblio/core.properties.sample-non-solrcloud $SOLR_PATH/vufind/biblio/core.properties
sudo chown -R solr $SOLR_PATH

# set java heap min/max
sudo sed -i 's/SOLR_JAVA_MEM=/#SOLR_JAVA_MEM=/' $SOLR_PATH/vufind/solr.in.finna.sh
sudo sed -i '/#SOLR_JAVA_MEM/a SOLR_JAVA_MEM="-Xms'"$JAVA_HEAP_MIN"' -Xmx'"$JAVA_HEAP_MAX"'"' $SOLR_PATH/vufind/solr.in.finna.sh
# disable Zookeeper & SolrCloud
sudo sed -i 's/ZK_/#ZK_=/' $SOLR_PATH/vufind/solr.in.finna.sh
sudo sed -i 's/SOLR_MODE/#SOLR_MODE=/' $SOLR_PATH/vufind/solr.in.finna.sh
# set allowed IPs
sudo sed -i -e '$ a SOLR_JETTY_HOST=\"'"$SOLR_JETTY_HOST"'\"' $SOLR_PATH/vufind/solr.in.finna.sh

# fix Solr local dir setting in VuFind
sudo sed -i '/;url *= */a local = '"$SOLR_PATH"'' $VUFIND2_PATH/local/config/vufind/config.ini

sudo yum -y install policycoreutils-python-utils policycoreutils-devel lsof
sudo semanage port -a -t http_port_t -p tcp 8983

#set as service
sudo cp $SOLR_PATH/vufind/solr.service /etc/systemd/system
# see https://stackoverflow.com/questions/62240348/pm2-startup-issue-with-centos-8-selinux
# this does not work from script, let's create .te-file directly
# sudo ausearch -c 'systemd' --raw | audit2allow -M solr
sudo tee -a solr.te >/dev/null <<EOF

module solr 1.0;

require {
	type init_t;
	type initrc_tmp_t;
	type default_t;
	class file read;
	class dir rmdir;
	class file open;

}

#============= init_t ==============
allow init_t default_t:file read;
allow init_t initrc_tmp_t:dir rmdir;
allow init_t default_t:file open;
EOF
# policycoreutils-devel needed
sudo make -f /usr/share/selinux/devel/Makefile solr.pp
sudo semodule -i solr.pp
sudo systemctl daemon-reload
sudo systemctl enable solr
sudo systemctl start solr
echo
echo "========================"
echo "...done installing Solr."
