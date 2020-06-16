### NDL-VuFind2-Vagrant

Vagrant setup for NDL VuFind2 with two separate guest virtual machines:
- **ubuntu** (default)
  - for development, uses NDL-VuFind2 files from the host's filesystem. Includes optional install of <a href="https://medium.com/@kitze/introducing-sizzy-a-tool-for-developing-responsive-websites-crazy-fast-39a8c0061992">Sizzy</a> to help in responsive & mobile development.
- **centos**
  - a testbed to build a personal test server; SELinux enabled so could maybe even be a rough outline to set-up a production server, who knows. Clones the latest NDL-VuFind2 from GitHub inside the guest.

#### Requirements

Mandatory:
- <a href="https://www.virtualbox.org">VirtualBox</a> (avoid _v5.0.28_ & _v5.1.8_ due to issues with _Composer_) - Mac users should also see <a href="https://developer.apple.com/library/archive/technotes/tn2459/_index.html">this</a> as you may need to allow the KEXT from Oracle if the VirtualBox install fails. **If you have network issues with v6.1.x use v6.0.x!**
- <a href="https://www.vagrantup.com">Vagrant</a> (avoid _v1.8.7_ due to issues with _curl_)

Optional:
- <a href="http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html">Oracle Instant Client</a> installer files downloaded from Oracle (a soul-selling registration needed), see the <a href="https://github.com/NatLibFi/NDL-VuFind2-Vagrant/tree/master/oracle">oracle/README</a> for details.
  - If the installer files are not found during provisioning, the Oracle installation will be skipped with a warning message. The message can be turned off by setting 'INSTALL_ORACLE_CLIENT=false' in the bootstrap files.

for _ubuntu_:
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (fork it!) cloned to the host computer

#### Set-Up

_ubuntu_ (<a href="https://app.vagrantup.com/ubuntu/boxes/bionic64">bionic64</a>):

* Clone the NDL-VuFind2-Vagrant files to the host computer, preferably (but this is not an absolute must) into a directory parallel to the NDL-VuFind2 working directory e.g. _path-to/NDL-VuFind2_ & _same-path-to/NDL-VuFind2-Vagrant_. The directory names can also be different than those presented here.

* Copy the _VagrantConf.rb.sample_ to _VagrantConf.rb_.
  * If the path to the NDL-VuFind2 working directory is other than _../NDL-VuFind2_ modify the _VagrantConf.rb_ **VufindPath** variable accordingly. The path can either be an absolute or a relative path as long as the NDL-VuFind2 files can be found there.<br/>

* Copy the _ubuntu.conf.sample_ to _ubuntu.conf_ and see the .conf file for possible install configuration changes (e.g. enabling Sizzy etc.) prior to running the VM.

If using sqlplus from Oracle:
* Put the _tnsnames.ora_ file in the _oracle/_ directory (or copy/create it into _/opt/oracle/instantclient_xx_x/_ in the guest afterwards).

_centos_ (<a href="https://app.vagrantup.com/centos/boxes/7">centos7</a>):

* Clone the NDL-VuFind2-Vagrant files to the host computer unless this is already done. If only using _centos_, any directory with sufficent user permissions will do. If using both _ubuntu_ & _centos_, the same directory with _ubuntu_ is fine.

* Copy the _VagrantConf.rb.sample_ to _VagrantConf.rb_ unless this is already done. There should be no need for any changes.

* Copy the _centos.conf.sample_ to _centos.conf_ and see the .conf file for possible install configuration changes prior to running the VM.

_both_:

If using Oracle:
* Put the downloaded Oracle installer files in the _oracle/_ directory and the VoyagerRestful_*.ini files in the _config/_ directory.

If using local RecordManager/Solr, some options exist for the records data:
* default (but bare minimum e.g. testing purposes): a sample data file exists in the _data/_ directory to be imported to the local Solr database via RecordManager during install
* more proper use: add your own data to the _data/_ directory before provisioning/installing **or** import your data manually from file(s) **or** set up harvesting sources after the provisioning/installing is done.

Without local database: use a remote Solr server (like the NDL development index - unfortunately, for limited users only)
* either set the EXTERNAL_SOLR_URL in the bootstrap files (also set INSTALL_SOLR + INSTALL_RM to _false_ as they are not needed), or
* add the external URL to the _vufind2/local/config/vufind/config.ini_ file after install.

#### Use

_ubuntu_:
- `vagrant up`
  - This will take a few minutes, so enjoy your beverage of choice!
  - Mac only!: NFS is enabled as default and Vagrant needs to modify _/etc/exports_ and will ask password for _sudo_ privileges on building the virtual environent and destroying it. This can be avoided by either modifying sudoers or more easily running `sudo scripts/nfs-sudoers_mac.sh` (see <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a> in Vagrant documentation for more details).
- Point your browser to <a href="http://localhost:8081/vufind2">http://localhost:8081/vufind2</a>
  - Blank page or errors: adjust VuFind config(s), reload browser page.
- When using Sizzy, point the browser to <a href="http://localhost:3033/?url=http://localhost:8081/vufind2">http://localhost:3033/?url=http://localhost:8081/vufind2</a>
  - If you forgot to enable Sizzy in ubuntu.conf, just run<br>`vagrant ssh -c "bash /vagrant/scripts/ubuntu_sizzy.sh"`

_centos_:
- `vagrant up centos`
  - Again, this will take a few minutes...
- `vagrant ssh -c "/usr/bin/mysql_secure_installation" centos` to add MySQL root password and remove anonymous user & test databases
- <a href="http://localhost:8082/vufind2">http://localhost:8082/vufind2</a>
  - Blank page or errors: adjust VuFind config(s) inside the VM, reload browser page.

Both machines can be run simultaneously provided the host has enough oomph.

**Solr**: `sudo service solr start|stop|restart|status` inside the VM to control the running state.
- Solr Admin UI can be accessed at
  - _ubuntu_: <a href="http://localhost:18983/solr">http://localhost:18983/solr</a>
  - _centos_: <a href="http://localhost:28983/solr">http://localhost:28983/solr</a>

**RecordManager & Importing Data**: As a default, the provisioning phase will install a sample dataset to the local index. It is recommended to use your own data. The easiest way is to add a data file and a proper datasources.ini file to the _data/_ directory + adjust the RECMAN_SOURCE, RECMAN_DATASOURCE & RECMAN_DATA variables in ubuntu/centos.conf prior to the `vagrant up` command. It is also possible to change the RECMAN_IMPORT to **false** and set up data harvesting inside the virtual machine after installation. For more details, see <a href="https://github.com/NatLibFi/RecordManager/blob/master/conf/datasources.ini.sample">datasources.ini.sample</a> and <a href="https://github.com/NatLibFi/RecordManager/wiki/Usage">RecordManager Usage</a>.
- <a href="https://github.com/NatLibFi/RecordManager/wiki">RecordManager Wiki</a> for additional information.

#### Useful Commands
* `vagrant reload`
  - reload the configuration changes made to _Vagrantfile_
* `vagrant suspend`
  - freeze the virtual machine, continue with `vagrant resume`
* `vagrant halt`
  - shut down the virtual machine, restart with `vagrant up`
* `vagrant destroy`
  - delete the virtual machine
* `vagrant ssh`
  - login to the running virtual machine (vagrant:vagrant) e.g. to restart Apache `sudo service apache2 restart` or to check Apache logs `sudo tail -f /var/log/apache2/error.log`, `sudo tail -f /var/log/apache2/access.log`
  - use option `-c` to run commands in guest via ssh e.g. to compile less to css:

    > vagrant ssh -c "less2css"

    or restart Apache `vagrant ssh -c "sudo service apache2 restart"` etc.
* `vagrant box update`
  - update the cached boxes if newer versions exist
* `vagrant box list`
  - show the cached box files, delete unnecessary ones with `vagrant box remove` or `vagrant box prune`
* `vagrant plugin install vagrant-vbguest`
  - for prolonged use, install <a href="https://github.com/dotless-de/vagrant-vbguest">vagrant-vbguest</a> plugin to keep the host machines's VirtualBox Guest Additions automatically updated
* ( `vagrant package --output ubuntu_vufind2.box`
  - package the virtual machine as a new base box, roughly 700MB or more - the _Vagrantfile_ needs to be edited to use the created box file. )

When addressing the _centos_ machine, just add `centos` at the end of each command.

<a href="https://docs.vagrantup.com/v2/cli/index.html">Vagrant documentation</a> for more info.

### Known Issues
- Possibly slightly slower than native LAMP/MAMP/WAMP but shouldn't be a real issue. YMMV though, so worst case, try adding more VirtualMemory in VagrantConf.rb (and/or v.cpus in Vagrantfile).<br>
  More speed can also be gained by enabling <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a>:
  - Mac users, (**NFS is now default**) admin password will be asked with every `vagrant up` & `vagrant destroy` unless you once run `sudo scripts/nfs-sudoers_mac.sh` or manually modify sudoers. See the previous link for more information.
  - Linux users, first remove the _if-else-end_ conditioning regarding _darwin_ in _Vagrantfile_, install `nfsd`, either manually modify sudoers or run `sudo scripts/nfs-sudoers_ubuntu.sh` or `sudo scripts/nfs-sudoers_fedora.sh` based on your platform. Please see the previous link for details.
  - Windows users are out of luck as NFS synced folders are ignored by Vagrant.
- If running Solr, VirtualMemory needs to be at least around 2048, which should work.

### Resources
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a>
- <a href="https://github.com/NatLibFi/finna-solr">finna-solr</a>
- <a href="http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html">Oracle Instant Client</a>
- <a href="https://github.com/NatLibFi/RecordManager">RecordManager</a> & <a href="https://github.com/NatLibFi/RecordManager/Wiki">Wiki</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.sizzy.co">Sizzy</a>
