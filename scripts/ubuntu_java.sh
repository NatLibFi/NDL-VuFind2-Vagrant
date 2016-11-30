#!/usr/bin/env bash

# add Java 8 repository; Solr 6 requires Java 8
sudo apt-add-repository -y ppa:webupd8team/java
sudo apt-get -q update

# install Java JDK
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer
