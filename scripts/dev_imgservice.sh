#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_IMGSERVICE" ]; then
  source /vagrant/dev.conf
fi
echo
echo "Installing FinnaImageService..."
echo "==============================="

sudo apt-get -y install docker.io
sudo systemctl start docker
sudo systemctl enable docker

sudo mkdir -p $IMGSERVICE_PATH
if [[ "$IMGSERVICE_BRANCH" == "master" ]]; then
  sudo git clone $IMGSERVICE_GIT $IMGSERVICE_PATH
else
  sudo git clone $IMGSERVICE_GIT --branch $IMGSERVICE_BRANCH --single-branch 
fi

cd $IMGSERVICE_PATH
sudo docker build -t pdf2jpg .
sudo docker run -d -p 36000:80 pdf2jpg
cd

echo
echo "====================================="
echo "...done installing FinnaImageService."
echo "====================================="
echo "Adjust the config.ini file manually!!"
