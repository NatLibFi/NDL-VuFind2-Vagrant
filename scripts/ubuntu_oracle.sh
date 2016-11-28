#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
[[ $INSTALL_ORACLE_CLIENT ]]
{
  source /vagrant/ubuntu.conf
}

# Check whether installer files exist
ORACLE_FILES_EXIST=false
for f in $ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip; do
  [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer ZIP files found!"
  break
done

# Oracle PHP OCI driver
if [ "$ORACLE_FILES_EXIST" = true ] ; then
  echo "Installing Oracle Instant Client..."
  sudo pear upgrade pear
  sudo mkdir -p /opt/oracle
  cd /opt/oracle
  sudo unzip -o "$ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip" -d ./
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so.* /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libocci.so.* /opt/oracle/instantclient_$OCI_VERSION/libocci.so
  sudo sh -c "echo /opt/oracle/instantclient_$OCI_VERSION > /etc/ld.so.conf.d/oracle-instantclient"
  if php --version | grep -q "PHP 7"; then
    # oci8 2.1.0 and up needs php7
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8"
  else
    # use older version
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8-2.0.10"
  fi
  sudo sh -c 'echo extension=oci8.so > /etc/php5/mods-available/oci8.ini'
  sudo ln -s /usr/include/php5 /usr/include/php
  sudo php5enmod oci8
  sudo service apache2 reload

  # PDO_OCI
  sudo pecl channel-update pear.php.net
  sudo mkdir -p /tmp/pear/download/
  cd /tmp/pear/download/
  sudo pecl download pdo_oci
  sudo tar xvf PDO_OCI-*.tgz
  cd PDO_OCI-*
  sudo curl -o config.m4 $OCI_CONFIG_URL
  sudo chmod +x config.m4
  sudo sed -i -e 's/function_entry pdo_oci_functions/zend_function_entry pdo_oci_functions/' pdo_oci.c
  sudo phpize
  sudo mkdir -p /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/sdk /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION/client
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION /opt/oracle/instantclient_$OCI_VERSION/lib/oracle/$OCI_DOT_VERSION/client/lib
  sudo ln -s /usr/include/php5 /usr/include/php
  sudo ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient_$OCI_VERSION,$OCI_DOT_VERSION
  sudo make
  sudo make install
  sudo sh -c 'echo extension=pdo_oci.so > /etc/php5/mods-available/pdo_oci.ini'
  sudo php5enmod pdo_oci
  sudo service apache2 reload

  # sqlplus
  sudo apt-get install -y rlwrap
  echo "alias sqlplus='rlwrap sqlplus'" >> /home/vagrant/.bashrc
  echo "export LD_LIBRARY_PATH=/opt/oracle/instantclient_$OCI_VERSION"  >> /home/vagrant/.bashrc
  echo "export SQLPATH=~/code/oracle-scripts/scripts:/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  echo "PATH=$PATH:/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  echo "export TNS_ADMIN=/opt/oracle/instantclient_$OCI_VERSION" >> /home/vagrant/.bashrc
  source /home/vagrant/.bashrc
  if [ -f $ORACLE_PATH/tnsnames.ora ]; then
    cp -rf $ORACLE_PATH/tnsnames.ora /opt/oracle/instantclient_$OCI_VERSION/
  fi

  # conf files
  shopt -s nullglob
  voyagers=($CONFIG_PATH/VoyagerRestful_*.ini)
  shopt -u nullglob
  if [ ${#voyagers[@]} -gt 0 ]; then
    cp -rf $CONFIG_PATH/VoyagerRestful_*.ini $VUFIND2_PATH/local/config/vufind/
    for i in "${voyagers[@]}"; do
      org=$(echo $i| cut -d'_' -f 2| cut -d'.' -f 1)
      sed -i '/\[Drivers\]$/a '"$org"' = VoyagerRestful' $VUFIND2_PATH/local/config/finna/MultiBackend.ini
    done
  fi

  echo "...done installing Oracle Instant Client."
fi
