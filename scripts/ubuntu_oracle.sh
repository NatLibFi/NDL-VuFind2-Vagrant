#!/usr/bin/env bash

# if not set, then script called from command line and variables need to be set
if [ -z "$INSTALL_ORACLE_CLIENT" ]; then
  source /vagrant/ubuntu.conf
fi

# Check whether installer files exist
ORACLE_FILES_EXIST=false
for f in $ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip; do
  [ -e "$f" ] && ORACLE_FILES_EXIST=true || echo "No Oracle installer ZIP files found!"
  break
done

# Oracle PHP OCI driver
if [ "$ORACLE_FILES_EXIST" = true ] ; then
  echo "Installing Oracle Instant Client..."
  echo "==================================="
  sudo pear upgrade pear
  sudo mkdir -p /opt/oracle
  cd /opt/oracle
  sudo unzip -o "$ORACLE_PATH/instantclient*linux.x64-$OCI_DOT_VERSION*.zip" -d ./
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so.* /opt/oracle/instantclient_$OCI_VERSION/libclntsh.so
  sudo ln -s /opt/oracle/instantclient_$OCI_VERSION/libocci.so.* /opt/oracle/instantclient_$OCI_VERSION/libocci.so
  sudo sh -c "echo /opt/oracle/instantclient_$OCI_VERSION > /etc/ld.so.conf.d/oracle-instantclient"
  # fix pecl - see https://serverfault.com/questions/589877/pecl-command-produces-long-list-of-errors
  sed -i "$ s|\-n||g" /usr/bin/pecl
  if php --version | grep -q "PHP 7"; then
    # oci8 2.1.0 and up needs php7
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8"
  else
    # use older version
    sudo sh -c "echo instantclient,/opt/oracle/instantclient_$OCI_VERSION | pecl install oci8-2.0.10"
  fi
  sudo sh -c 'echo extension=oci8.so > /etc/php/7.0/mods-available/oci8.ini'
  sudo ln -s /usr/include/php7 /usr/include/php
  sudo phpenmod oci8
  sudo service apache2 reload

  # sqlplus
  sudo apt-get install -y rlwrap
  echo "alias sqlplus='rlwrap sqlplus'" >> /home/ubuntu/.bashrc
  echo "export LD_LIBRARY_PATH=/opt/oracle/instantclient_$OCI_VERSION"  >> /home/ubuntu/.bashrc
  echo "export SQLPATH=~/code/oracle-scripts/scripts:/opt/oracle/instantclient_$OCI_VERSION" >> /home/ubuntu/.bashrc
  echo "PATH=$PATH:/opt/oracle/instantclient_$OCI_VERSION" >> /home/ubuntu/.bashrc
  echo "export TNS_ADMIN=/opt/oracle/instantclient_$OCI_VERSION" >> /home/ubuntu/.bashrc
  source /home/ubuntu/.bashrc
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
  echo "========================================="
  echo "...done installing Oracle Instant Client."
fi
