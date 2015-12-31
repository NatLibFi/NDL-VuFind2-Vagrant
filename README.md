### NDL-VuFind2-Vagrant
Vagrant setup for NDL VuFind2 with two separate guest virtual machines:
- **ubuntu** (default)
  - for development, uses NDL-VuFind2 files from the host's filesystem
- **centos**
  - a testbed to build a personal test server; SELinux enabled so could maybe even be a rough outline to set-up a production server, who knows. Clones the latest NDL-VuFind2 from GitHub inside the guest.

#### Requirements

- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html">Oracle Instant Client</a> installer files downloaded from Oracle (a soul-selling registration needed), see the <a href="https://github.com/tmikkonen/NDL-VuFind2-Vagrant/tree/master/oracle">oracle/README</a> for details.
  - The files can be skipped if holdings information is not needed. In this case, please set 'INSTALL_ORACLE_CLIENT=false' in the bootstrap files. 

_ubuntu_:
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (fork it!) cloned to the host computer

#### Set-Up

_ubuntu_:

Put the NDL-VuFind2-Vagrant files in a directory parallel to the NDL-VuFind2 working directory e.g. _path-to/vufind2_ & _same-path-to/vagrant_vufind2_. If the working directory is other than _vufind2_, modify the _Vagrantfile_ accordingly.<br/>
If using sqlplus from Oracle, put the _tnsnames.ora_ file in the _oracle/_ directory (or copy/create it into _/opt/oracle/instantclient_xx_x/_ in the guest afterwards).

_centos_:

If only using _centos_, any directory with sufficent user permissions will do. If using both, the same directory with _ubuntu_ is fine.

_both/either_:

If using Oracle, put the downloaded Oracle installer files in the _oracle/_ directory and the VoyagerRestful_*.ini files in the _config/_ directory.

For the records data, some options exist:
* bare minimum (e.g. testing purposes): add a sample data file to the _config/_ directory to import to the local Solr database via RecordManager during install
* more proper use: import your data manually from file(s) or set up harvesting sources after the provisioning/installing is done
* without local database: use a remote Solr server (like the NDL development index - unfortunately, for limited users only)
  - either set the 'EXTERNAL_SOLR_URL' in the bootstrap files (but note that the Solr and RecordManager won't be installed at all, then!), or
  - add the external URL to the _vufind2/local/config/vagrant/vufind/config.ini_ file after install.

See the bootstrap files for possible install configuration changes prior to running the VMs.

#### Use

_ubuntu_:
- 'vagrant up'
  - This will take a few minutes, so enjoy your beverage of choice!
- 'vagrant rsync-auto'
  - Needs to be run manually to make sure the config changes are synced to the guest machine. 
- Point your browser to <a href="http://localhost:8081">http://localhost:8081</a>
  - Blank page or errors: adjust the config(s), check that rsync works (run 'vagrant rsync-auto' if not), reload browser page.

_centos_:
- 'vagrant up centos'
  - Again, this will take a few minutes...
- 'vagrant ssh centos'
- '/usr/bin/mysql_secure_installation' to add MySQL root password and remove anonymous user & test databases
- 'exit'
- <a href="http://localhost:8082">http://localhost:8082</a>
  - Blank page or errors: adjust the config(s) inside the VM, reload browser page.

Both machines can be run simultaneously provided the host has enough oomph.

**Solr**: 'sudo service start|stop|restart|status' inside the VM to control the running state.
- Solr Admin UI can be accessed at
  - _ubuntu_: <a href="http://localhost:18983/solr">http://localhost:18983/solr</a>
  - _centos_: <a href="http://localhost:28983/solr">http://localhost:28983/solr</a>

**RecordManager & Importing Data**: If SAMPLE_DATA location is set in the bootstrap files and the corresponding xml file present, the provisioning phase will install a sample dataset to the local index. It is recommended to delete the sample config found in /usr/local/RecordManager/conf/datasources.ini and create your own (see <a href="https://github.com/NatLibFi/RecordManager/blob/master/conf/datasources.ini.sample">datasources.ini.sample</a> and <a href="https://github.com/NatLibFi/RecordManager/wiki/Usage">RecordManager Usage</a>).
- <a href="https://github.com/NatLibFi/RecordManager/wiki">RecordManager Wiki</a> for additional information.

#### Useful Commands
* 'vagrant reload'
  - reload the configuration changes made to _Vagrantfile_
* 'vagrant suspend'
  - freeze the virtual machine, continue with 'vagrant resume'
* 'vagrant halt'
  - shut down the virtual machine, restart with 'vagrant up'
* 'vagrant destroy'
  - delete the virtual machine
* 'vagrant ssh'
  - login to the running virtual machine (vagrant:vagrant) e.g. to restart Apache ('sudo service apache2 restart') or to check Apache logs in /var/log/apache2/ ('sudo tail -f /var/log/apache2/error.log', 'sudo tail -f /var/log/apache2/access.log')
* 'vagrant box update'
  - update the cached boxes if newer versions exist 
* 'vagrant box list'
  - show the cached box files, delete unnecessary ones with 'vagrant box remove'
* 'vagrant plugin install vagrant-vbguest'
  - for prolonged use, install <a href="https://github.com/dotless-de/vagrant-vbguest">vagrant-vbguest</a> plugin to keep the host machines's VirtualBox Guest Additions automatically updated
* ( 'vagrant package --output ubuntu_vufind2.box'
  - package the virtual machine as a new base box, roughly 700MB or more - the _Vagrantfile_ needs to be edited to use the created box file. )

When addressing the _centos_ machine, just add ' centos' at the end of each command.

<a href="https://docs.vagrantup.com/v2/cli/index.html">Vagrant documentation</a> for more info.

### Known Issues
- Slower than native LAMP/MAMP. You can try adding more v.memory/v.cpus in Vagrantfile
- Copying the _vufind2/local_ directory inside the _ubuntu_ virtual machine is a ~~dirty~~ hack to get the virtual machine to access _local/cache_. However, the changes in the host under _local/config/vagrant_ are now rsynced automatically to the virtual machine. If for some reason they are not, run 'vagrant rsync-auto' again. The rsyncing comes with the slight caveat for Windows users who need to download <a href="http://www.rsync.net/resources/binaries/cwRsync_5.4.1_x86_Free.zip">rsync</a> and install it with the default options
- If running Solr, v.memory needs to be at least around 2048, which should work.

### Resources
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a>
- <a href="https://github.com/NatLibFi/NDL-VuFind-Solr">NDL-VuFind-Solr</a>
- <a href="http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html">Oracle Instant Client</a>
- <a href="https://github.com/NatLibFi/RecordManager">RecordManager</a> & <a href="https://github.com/NatLibFi/RecordManager/Wiki">Wiki</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="https://www.virtualbox.org">VirtualBox</a>
