#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_ORACLE_CLIENT" ]; then
  source /vagrant/centos.conf
fi

# Check whether installer files exist
ORACLE_FILES_EXIST=false
for f in $ORACLE_PATH/oracle-instantclient$OCI_VERSION*.x86_64.rpm; do
  [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer RPM files found!"
  break
done

# Oracle PHP OCI driver
if [ "$ORACLE_FILES_EXIST" = true ]; then
  echo "Installing Oracle Instant Client..."
  echo "==================================="
  sudo yum -y install libaio
  sudo mkdir -p /tmp/oracle
  cd /tmp/oracle
  sudo cp $ORACLE_PATH/oracle-instantclient$OCI_VERSION*.x86_64.rpm ./
  sudo rpm -Uvh oracle-instantclient$OCI_VERSION*-basic-*.x86_64.rpm
  sudo rpm -Uvh oracle-instantclient$OCI_VERSION*-devel-*.x86_64.rpm
  sudo chcon -t textrel_shlib_t /usr/lib/oracle/$OCI_VERSION/client64/lib/*.so
  #sudo execstack -c /usr/lib/oracle/$VERSION/client64/lib/*.so.*  # no execstack
  sudo setsebool -P httpd_execmem 1
  sudo yum -y install gcc
  sudo sh -c "echo /usr/lib/oracle/$OCI_VERSION/client64 > /etc/ld.so.conf.d/oracle-instantclient"
  if php --version | grep -q "PHP 7"; then
    # oci8 2.1.0 and up needs php7
    sudo sh -c "echo instantclient,/usr/lib/oracle/$OCI_VERSION/client64/lib | pecl install oci8"
  else
    # use older version
    sudo sh -c "echo instantclient,/usr/lib/oracle/$OCI_VERSION/client64/lib | pecl install oci8-2.0.10"
  fi
  sudo chcon system_u:object_r:textrel_shlib_t:s0 /usr/lib64/php/modules/oci8.so
  sudo chmod +x /usr/lib64/php/modules/oci8.so
  sudo sh -c 'echo extension=oci8.so > /etc/php.d/oci8.ini'
  sudo service httpd reload

  # PDO_OCI
  sudo mkdir -p /tmp/pear/download/
  cd /tmp/pear/download/
  sudo pecl channel-update pear.php.net
  sudo pecl download pdo_oci
  sudo tar xvf PDO_OCI-*.tgz
  cd PDO_OCI-*
  sudo curl -o config.m4 $OCI_CONFIG_URL
  sudo sed -i -e 's/function_entry pdo_oci_functions/zend_function_entry pdo_oci_functions/' pdo_oci.c
  sudo ln -s /usr/include/oracle/$OCI_VERSION/client64 /usr/include/oracle/$OCI_VERSION/client
  sudo ln -s /usr/lib/oracle/$OCI_VERSION/client64 /usr/lib/oracle/$OCI_VERSION/client
  sudo phpize
  sudo ./configure --with-pdo-oci=instantclient,/usr,$OCI_VERSION
  sudo make
  sudo make install
  sudo chcon system_u:object_r:textrel_shlib_t:s0 /usr/lib64/php/modules/pdo_oci.so
  sudo sh -c 'echo extension=pdo_oci.so > /etc/php.d/pdo_oci.ini'
  sudo service httpd reload
  sudo setsebool -P httpd_can_network_relay=1
  sudo setsebool -P httpd_can_network_connect 1

  # conf files
  shopt -s nullglob
  voyagers=(/vagrant/config/VoyagerRestful_*.ini)
  shopt -u nullglob
  if [ ${#voyagers[@]} -gt 0 ]; then
    cp -rf $CONFIG_PATH/VoyagerRestful_*.ini $VUFIND2_PATH/local/config/vufind/
    for i in "${voyagers[@]}"; do
      org=$(echo $i| cut -d'_' -f 2| cut -d'.' -f 1)
      sed -i '/\[Drivers\]$/a '"$org"' = VoyagerRestful' $VUFIND2_PATH/local/config/finna/MultiBackend.ini
    done
  fi
  echo "========================================="
  echo "...done installing Oracle Instant Client."
fi
