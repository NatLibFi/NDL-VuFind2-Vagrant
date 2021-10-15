## NDL-VuFind2-Vagrant

- [Overview](#overview)
- [Requirements](#requirements)
- [Set-Up](#set-up)
- [Use](#use)
  * [Useful Commands](#useful-commands)
- [Email Testing Environment](#email-testing-environment)
  * [Due Date Reminders](#due-date-reminders)
  * [Scheduled Alerts](#scheduled-alerts)
- [Troubleshooting](#troubleshooting)
- [Known Issues](#known-issues)
- [Resources](#resources)

### Overview

Vagrant setup for <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL VuFind2</a> with two separate guest virtual machines:
- **ubuntu** (default)
  - for development, uses NDL-VuFind2 files from the host's filesystem. An added development feature is the option to have also <a href="https://github.com/NatLibFi/RecordManager">RecordManager</a> on the host's native filesystem.
- **centos**
  - a testbed to build a personal test server; SELinux enabled so could maybe even be a rough outline to set-up a production server, who knows. Clones the latest NDL-VuFind2 from GitHub inside the guest.

### Requirements

Mandatory:
- <a href="https://www.virtualbox.org">VirtualBox</a> (avoid _v5.0.28_ & _v5.1.8_ due to issues with _Composer_)  
  - Mac users should also see <a href="https://developer.apple.com/library/archive/technotes/tn2459/_index.html">this</a> as you may need to allow the KEXT from Oracle if the VirtualBox install fails.
  - **With v6.1.x see [Known Issues](#known-issues)** (if all else fails [v6.0.x](https://www.virtualbox.org/wiki/Download_Old_Builds) should still work!)
- <a href="https://www.vagrantup.com">Vagrant</a> (avoid _v1.8.7_ due to issues with _curl_)

Optional:
- <a href="http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html">Oracle Instant Client</a> installer files downloaded from Oracle (a soul-selling registration needed), see the <a href="https://github.com/NatLibFi/NDL-VuFind2-Vagrant/tree/master/oracle">oracle/README</a> for details.
  - If the installer files are not found during provisioning, the Oracle installation will be skipped with a warning message. The message can be turned off by setting 'INSTALL_ORACLE_CLIENT=false' in the bootstrap files.

for _ubuntu_:
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (fork it!) cloned to the host computer
- <a href="https://github.com/NatLibFi/RecordManager">RecordManager</a> also cloned to the host (optional)

### Set-Up

_ubuntu_ (<a href="https://app.vagrantup.com/ubuntu/boxes/bionic64">bionic64</a>):

* Clone the NDL-VuFind2-Vagrant files to the host computer, preferably (but this is not an absolute must) into a directory parallel to the NDL-VuFind2 working directory e.g. _path-to/NDL-VuFind2_ & _same-path-to/NDL-VuFind2-Vagrant_. The directory names can also be different than those presented here. All the same applies also to RecordManager files if using it on the host.

* Run `vagrant up` once or manually copy _VagrantConf.rb.sample_ to _VagrantConf.rb_.
  * If the path to the NDL-VuFind2 working directory is other than _../NDL-VuFind2_ modify the _VagrantConf.rb_ **VufindPath** variable accordingly. The path can either be an absolute or a relative path as long as the NDL-VuFind2 files can be found there. Similar attention to possible RecordManager directory should be used.<br/>

* Run `vagrant up` again or manually copy _ubuntu.conf.sample_ to _ubuntu.conf_ and see the file for possible install configuration changes (e.g. using RecordManager on host or enabling Sizzy etc.) prior to running the VM in full.

If using **sqlplus** from Oracle:
* Put the _tnsnames.ora_ file in the _oracle/_ directory (or copy/create it into _/opt/oracle/instantclient_xx_x/_ in the guest afterwards).

_centos_ (<a href="https://app.vagrantup.com/centos/boxes/7">centos7</a>):

* Clone the NDL-VuFind2-Vagrant files to the host computer **unless this is already done**. If only using _centos_, any directory with sufficent user permissions will do. If using both _ubuntu_ & _centos_, the same directory with _ubuntu_ is fine.

* Run `vagrant up centos` once or manually copy _VagrantConf.rb.sample_ to _VagrantConf.rb_ **unless this is already done**. There should be no need for any changes.

* Run `vagrant up centos` again or manually copy _centos.conf.sample_ to _centos.conf_ and see the file for possible install configuration changes prior to running the VM in full.

_both_:

If using Oracle:
* Put the downloaded Oracle installer files in the _oracle/_ directory and the VoyagerRestful_*.ini files in the _config/_ directory.

The default is to run Solr/RecordManager locally, some configuration options still exist (see also _Without local database_):
* Install both inside the guest VM
  > INSTALL_SOLR=true (default: true)
  > INSTALL_RECMAN=true (default: true)

* Use cloned RecordManager files on the host system (ubuntu.conf)
  > RECMAN_DEV=true (default: false)

Regarding the records data:
* default (but bare minimum e.g. testing purposes): a sample data file exists in the _data/_ directory to be imported to the local Solr database via RecordManager during install
* more proper use: add your own data to the _data/_ directory before provisioning/installing **or** import your data manually from file(s) **or** set up harvesting sources after the provisioning/installing is done.

Without local database: use a remote Solr server (like the NDL development index - unfortunately, _limited users only_)
* either set the EXTERNAL_SOLR_URL in the conf files (also set INSTALL_SOLR + INSTALL_RECMAN to _false_ as they are not needed), or
* add the external URL to the _NDL-VuFind2/local/config/vufind/config.ini_ file after install.

### Use

_ubuntu_:
- `vagrant up`
  - This will take a few minutes, so enjoy your beverage of choice!
  - Mac only! - NFS is enabled as default and Vagrant needs to modify _/etc/exports_ and will ask password for _sudo_ privileges on building the virtual environent and destroying it. This can be avoided by either modifying sudoers or more easily running `sudo scripts/nfs-sudoers_mac.sh` (see <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a> in Vagrant documentation for more details).
- Point your browser to <a href="http://localhost:8081/vufind2">http://localhost:8081/vufind2</a>
  - Blank page or errors: adjust VuFind config(s), reload browser page. See also [Troubleshooting](#troubleshooting).
- No integrated responsive/mobile development tool but try the native open source <a href="https://responsively.app/#Features">Responsively App</a> (also on <a href="https://github.com/manojVivek/responsively-app">GitHub</a>).
- If you don't install Solr & RecordManager at `vagrant up` startup you can add them to the already started virtual machine later by first setting their install options to true in _ubuntu.conf_ and then running consecutively<br>`vagrant ssh -c "bash /vagrant/scripts/ubuntu_solr.sh"`<br>`vagrant ssh -c "bash /vagrant/scripts/ubuntu_recman.sh"`
  - This is quicker than `vagrant destroy` + `vagrant up` if building the VM from the ground up is not needed or prefered.

_centos_:
- `vagrant up centos`
  - Again, this will take a few minutes...
- `vagrant ssh -c "/usr/bin/mysql_secure_installation" centos` to add MySQL root password and remove anonymous user & test databases
- <a href="http://localhost:8082/vufind2">http://localhost:8082/vufind2</a>
  - Blank page or errors: adjust VuFind config(s) inside the VM, reload browser page. See also [Troubleshooting](#troubleshooting).

Both machines can be run simultaneously provided the host has enough oomph.

**Solr**: `sudo service solr start|stop|restart|status` inside the VM to control the running state.
- Solr Admin UI can be accessed at
  - _ubuntu_: <a href="http://localhost:18983/solr">http://localhost:18983/solr</a>
  - _centos_: <a href="http://localhost:28983/solr">http://localhost:28983/solr</a>

**RecordManager & Importing Data**: As a default, the provisioning phase will install a sample dataset to the local index. It is recommended to use your own data. The easiest way is to add a data file and a proper datasources.ini file to the _data/_ directory + adjust the RECMAN_SOURCE, RECMAN_DATASOURCE & RECMAN_DATA variables in ubuntu/centos.conf prior to the `vagrant up` command. It is also possible to change the RECMAN_IMPORT to **false** and set up data harvesting after installation. For more details, see <a href="https://github.com/NatLibFi/RecordManager/blob/master/conf/datasources.ini.sample">datasources.ini.sample</a> and <a href="https://github.com/NatLibFi/RecordManager/wiki/Usage">RecordManager Usage</a>.
- <a href="https://github.com/NatLibFi/RecordManager/wiki">RecordManager Wiki</a> for additional information.

#### Useful Commands
* `vagrant reload`
  - reload the configuration changes made to _VagrantConf.rb_ file
* `vagrant suspend`
  - freeze the virtual machine, continue with `vagrant resume`
* `vagrant halt`
  - shut down the virtual machine, restart with `vagrant up`
* `vagrant destroy`
  - delete the virtual machine
* `vagrant ssh`
  - login to the running virtual machine (vagrant:vagrant) e.g. to restart Apache `sudo service apache2 restart` or to check Apache logs `sudo tail -f /var/log/apache2/error.log`, `sudo tail -f /var/log/apache2/access.log`
  - use option `-c` to run commands in guest via ssh e.g. to compile less to css:

    `vagrant ssh -c "less2css"`

    or restart Apache `vagrant ssh -c "sudo service apache2 restart"` etc.
* `vagrant box update`
  - update the cached boxes if newer versions exist
* `vagrant box list`
  - show the cached box files, delete unnecessary ones with `vagrant box remove` or `vagrant box prune` (add `-h` for help) e.g.
  
    `vagrant box remove ubuntu/bionic64 --box-version 20200701.0.0`
* `vagrant plugin install vagrant-vbguest`
  - for prolonged use, install <a href="https://github.com/dotless-de/vagrant-vbguest">vagrant-vbguest</a> plugin to keep the host machines's VirtualBox Guest Additions automatically updated
* ( `vagrant package --output ubuntu_vufind2.box`
  - package the virtual machine as a new base box, roughly 700MB or more - the _VagrantConf.rb_ file needs to be edited to use the created box file. )

When addressing the _centos_ machine, just add `centos` at the end of each command.

<a href="https://docs.vagrantup.com/v2/cli/index.html">Vagrant documentation</a> for more info.

### Email Testing Environment
Testing exists only in the _ubuntu_ VM.

- ubuntu.conf:
  >EMAIL_TEST_ENV=true
- add the settings below & adjust the [Mail] section accordingly - you need a working mail server - in _NDL-VuFind2/local/config/vufind/config.ini_
  ```
  [Site]
  institution = testi

  [Account]
  force_first_scheduled_email = true

  [Mail]
  host            = localhost
  port            = 25
  ;username       = user
  ;password       = "pass"  ; better to use quotes
  ; If set to false, users can send anonymous emails; otherwise, they must log in first
  require_login   = false
  ```
  - There might also be need to use the setting below but YMMV
    ```
    [Catalog]
    driver = Demo
    ```
- After `vagrant up` use **127.0.0.1** instead of localhost i.e. <a href="http://127.0.0.1:8081/vufind2">http://127.0.0.1:8081/vufind2</a> to log in as a (new) test user.
#### Due Date Reminders
- in user profile add the email address to receive the messages, set Due date reminders via email
- run `vagrant ssh -c "duedatereminder"`
#### Scheduled Alerts
- in user profile add the email address to receive the messages, if not already set
- save a search or two, in Saved searched set the Alert schedule
- run `vagrant ssh -c "scheduledalert"`

The email address in user profile should receive the messages. Note that another test user needs to be set up to run the made-up scheduled alerts again - turning them off and back on _might_ work but this is untested. 

### Troubleshooting

1. Check the network connection is working. The virtual environment needs to load from several Internet resources and cannot build itself properly without them. Note that there might also be problems with the cloud resources themselves.

2. As NDL-VuFind2 is being actively developed some new settings and configuration options will be presented in its _.ini/yaml/json.sample_ files from time to time. While building the virtual machine these files are only copied if previous ones don't already exist. Therefore if problems arise there might be need to make a backup of the _.ini/yaml/json_ files in _local/config/vufind/_ & _local/config/finna/_ before deleting all of them (not the _.sample_ ones!). The files will then be copied anew next time the virtual machine is succesfully build. If needed the old settings can now be carried over manually from the backups.  
**A telltale sign of this is usually when the ubuntu machine fails to function properly or the PHP server crashes while the centos machine is working properly** (if built).

3. The Ubuntu basebox is updated quite regularly so after `vagrant box update` it is not very common but quite possible that something breaks in the install scripts. If this happens and items 1 & 2 are already ruled out, run `vagrant up 2>&1 | tee ./vagrant-log.txt` with the default ubuntu.conf settings + create an issue describing shortly what happened and include the logfile.

4. "Cannot shutdown/remove VM - HELP!"  
Often (but not always) it is possible to use the VirtualBox GUI to remove the troublesome VM.  
If this is not the case try VBoxManage:
- Find the name (or ID) of the VM you want to remove:  
`VBoxManage list vms`  
- Shutdown the VM:  
`VBoxManage startvm NAME(OR ID) --type emergencystop`
- Delete the VM:  
`VBoxManage unregistervm NAME(OR ID) --delete`


### Known Issues
- Possibly slightly slower than native LAMP/MAMP/WAMP but shouldn't be a real issue. YMMV though, so worst case, try adding more VirtualMemory in VagrantConf.rb (and/or v.cpus in Vagrantfile).<br>
  More speed can also be gained by enabling <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a>:
  - Mac users, (**NFS is now default**) admin password will be asked with every `vagrant up` & `vagrant destroy` unless you once run `sudo scripts/nfs-sudoers_mac.sh` or manually modify sudoers. See the previous link for more information.
  - Linux users, first remove the _if-else-end_ conditioning regarding _darwin_ in _Vagrantfile_, install `nfsd`, either manually modify sudoers or run `sudo scripts/nfs-sudoers_ubuntu.sh` or `sudo scripts/nfs-sudoers_fedora.sh` based on your platform. Please see <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a> for details.
  - Windows users are out of luck as NFS synced folders are ignored by Vagrant.
- Virtualbox v6.1.x is known to have some permission issues on occasion, especially with macs. Make sure you have given full disk access to Terminal in _System Prefences > Security & Privacy > Privacy_ (also check for relevant programs if using integrated terminal in VSCode etc.). More <a href="https://github.com/hashicorp/vagrant/blob/80e94b5e4ed93a880130b815329fcbce57e4cfed/website/pages/docs/synced-folders/nfs.mdx#troubleshooting-nfs-issues">NFS troubleshooting</a>.
- If running Solr, VirtualMemory needs to be at least around 2048, which should work.

### Resources
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a>
- <a href="https://github.com/NatLibFi/finna-solr">finna-solr</a>
- <a href="http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html">Oracle Instant Client</a>
- <a href="https://github.com/NatLibFi/RecordManager">RecordManager</a> & <a href="https://github.com/NatLibFi/RecordManager/Wiki">Wiki</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://responsively.app/">Responsively.app</a>
