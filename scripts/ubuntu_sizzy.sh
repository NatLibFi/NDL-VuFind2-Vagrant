#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_SIZZY" ]; then
  source /vagrant/ubuntu.conf
fi

# Solr
echo "Installing Sizzy..."
echo "=================="

# docker
sudo apt-get -y install docker.io
sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
sudo docker run -d --name sizzy -p 3033:80 $SIZZY_DOCKER

echo "========================"
echo "...done installing Sizzy."
