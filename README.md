## NDL-VuFind2-Vagrant

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Set-Up](#set-up)
- [Use](#use)
  * [Useful Commands](#useful-commands)
- [Email Testing Environment](#email-testing-environment)
  * [Due Date Reminders](#due-date-reminders)
  * [Scheduled Alerts](#scheduled-alerts)
- [Unit Tests](#unit-tests)
- [Troubleshooting](#troubleshooting)
- [Known Issues](#known-issues)
- [Resources](#resources)

### Overview

Vagrant setup for <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL VuFind2</a> with two separate guest virtual machines:
- **ubuntu** (default)
  - for development, uses NDL-VuFind2 files from the host's filesystem. An added development feature is the option to have also <a href="https://github.com/NatLibFi/RecordManager-Finna">RecordManager-Finna</a> on the host's native filesystem. _This is the one you will most likely be using_.
- **alma**
  - a testbed to build a personal test server; SELinux enabled so could maybe even be a rough outline to set-up a production server, who knows. Clones the latest NDL-VuFind2 from GitHub inside the guest.

### Requirements

- <a href="https://www.vagrantup.com">Vagrant</a>

  AND a provider:
- <a href="https://www.virtualbox.org">VirtualBox</a> (**default** for ease of use, not for performance) 
  - **v7.xx recommended**
  - v6.1.x Mac users should see [this](https://developer.apple.com/library/archive/technotes/tn2459/_index.html)

  OR
- [QEMU](https://www.qemu.org/download/#macos) (macOS only)  
  Note: For Apple M1/M2 CPUs this is the only tested option
 
  OR 
- [libvirt](https://libvirt.org/index.html) (Linux only)

(Note:
- [Hyper-V](https://www.vagrantup.com/docs/providers/hyperv) (Windows only) may work if using SMBv1 on the host for sharing but is untested - you have been warned!)

Also for _ubuntu_ VM:
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (_fork it!_) cloned to the host computer (**mandatory**)
- <a href="https://github.com/NatLibFi/RecordManager-Finna">RecordManager-Finna</a> also cloned to the host (**optional**)
- <a href="https://github.com/NatLibFi/finna-ui-components">finna-ui-components</a> also cloned to the host (**optional**)

### Installation

See [Wiki](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/wiki) for more platform specific information when not using VirtualBox.

### Set-Up

_ubuntu_ ([jammy64](https://app.vagrantup.com/ubuntu/boxes/jammy64)):

* Clone the NDL-VuFind2-Vagrant files to the host computer, preferably (but this is not an absolute must) into a directory parallel to the NDL-VuFind2 working directory e.g. _path-to/NDL-VuFind2_ & _same-path-to/NDL-VuFind2-Vagrant_. The directory names can also be different than those presented here. All the same applies also to RecordManager files if using it on the host.

* Run `vagrant up` once or manually copy _VagrantConf.rb.sample_ to _VagrantConf.rb_.
  * If the path to the NDL-VuFind2 working directory is other than _../NDL-VuFind2_ modify the _VagrantConf.rb_ <a href="https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/VagrantConf.rb.sample#L4">VufindPath</a> variable accordingly. The path can either be an absolute or a relative path as long as the NDL-VuFind2 files can be found there. Similar attention to possible RecordManager directory should be used.<br/>
  * Adjust also <a href="https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/bd4bd3e9affd8dbd47ca69a2e4c602d82afac8ff/VagrantConf.rb.sample#L45">VMProvider</a> accordingly if not using VirtualBox.

* Run `vagrant up` again or manually copy _ubuntu.conf.sample_ to _ubuntu.conf_ and see the file for possible install configuration changes (e.g. using RecordManager on host or remote Solr server etc.) prior to running the VM in full.

_alma_ ([almalinux9](https://app.vagrantup.com/almalinux/boxes/9)):

* Clone the NDL-VuFind2-Vagrant files to the host computer **unless this is already done**. If only using _alma_, any directory with sufficent user permissions will do. If using both _ubuntu_ & _alma_, the same directory with _ubuntu_ is fine.

* Run `vagrant up alma` once or manually copy _VagrantConf.rb.sample_ to _VagrantConf.rb_ **unless this is already done**. There should be no need for any changes.

* Run `vagrant up alma` again or manually copy _alma.conf.sample_ to _alma.conf_ and see the file for possible install configuration changes prior to running the VM in full.

_both/either_:

The default is to install & run [Finna Solr](https://github.com/NatLibFi/finna-solr) & [RecordManager-Finna](https://github.com/NatLibFi/RecordManager-Finna) locally inside the VM. Some configuration options still exist (see also [Without local database](#without-local-database)) e.g. for RecordManager development:
* Install only Finna Solr inside the guest VM
  > INSTALL_SOLR=true  
  > INSTALL_RECMAN=false

* Use cloned RecordManager files on the host system instead of the guest VM (ubuntu.conf only):
  > [RECMAN_DEV](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/ubuntu.conf.sample#L75)=true ;default: false

Regarding the records data:
* default (but bare minimum for testing purposes): a sample data file exists in the [_data/_](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/tree/master/data) directory to be imported to the local Solr database via RecordManager during install
* more proper use: add your own data to the _data/_ directory before provisioning/installing **or** import your data manually from file(s) OR set up harvesting sources after the provisioning/installing is done. See [RecordManager & Importing Data](#importing-data).

<span id="without-local-database">**Without local database**</span>: use a remote Solr server (like the _NDL development index_ - unfortunately, **limited users only**)
* either set the EXTERNAL_SOLR_URL in the conf files (also set INSTALL_SOLR + INSTALL_RECMAN to _false_ as they are not needed), or
* add the [external URL](https://github.com/NatLibFi/NDL-VuFind2/blob/dev/local/config/vufind/config.ini.sample#L15) to the _NDL-VuFind2/local/config/vufind/config.ini_ file after install.

If not using VirtualBox, see [Wiki](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/wiki) for more platform and provider specific configuration options for [QEMU](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/wiki/macOS#qemu-configuration) and [libvirt](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/wiki/Linux#libvirt-configuration).

### Use

_ubuntu_:
- `vagrant up`
  - This will take a few minutes, so enjoy your beverage of choice!
- Point your browser to <a href="http://localhost:8081/vufind2">http://localhost:8081/vufind2</a>  
  blank page or errors:
  - adjust VuFind config(s), reload browser page
  - check forwarded ports `vagrant port` and adjust the URL if needed, reload browser page
  - see also [Troubleshooting](#troubleshooting)
- No integrated responsive/mobile development tool but try the native open source <a href="https://responsively.app/#Features">Responsively App</a> (also on <a href="https://github.com/manojVivek/responsively-app">GitHub</a>).
- If you don't install Solr & RecordManager at `vagrant up` startup you can add them to the already started virtual machine later by first setting their install options to true in _ubuntu.conf_ and then running consecutively<br>`vagrant ssh -c "bash /vagrant/scripts/ubuntu_solr.sh"`<br>`vagrant ssh -c "bash /vagrant/scripts/ubuntu_recman.sh"`
  - This is quicker than `vagrant destroy` + `vagrant up` if building the VM from the ground up is not needed or preferred.

**Note**: If RSync is enabled and you are making developement changes run:
* `vagrant rsync-auto`
to let vagrant keep up with the made changes and sync them into the VM–you can use another tab or start a screen session for running the command in the backround.
(Another way is to manually run `vagrant rsync`
before testing the made changes but the previous command automizes this.)

_alma_:
- `vagrant up alma`
  - Again, this will take a few minutes...
- `vagrant ssh -c "/usr/bin/mysql_secure_installation" alma` to add MySQL root password and remove anonymous user & test databases
- <a href="http://localhost:8082/vufind2">http://localhost:8082/vufind2</a>  
  blank page or errors:
  - adjust VuFind config(s) inside the VM, reload browser page
  - check forwarded ports `vagrant port alma` and adjust the URL if needed, reload browser page
  - see also [Troubleshooting](#troubleshooting).

Both machines can be run simultaneously provided the host has enough oomph–except with QEMU provider. See [Known Issues](#known-issues).

**Solr**: `sudo service solr start|stop|restart|status` inside the VM to control the running state.
- Solr Admin UI can be accessed at
  - _ubuntu_: <a href="http://localhost:18983/solr">http://localhost:18983/solr</a>
  - _alma_: <a href="http://localhost:28983/solr">http://localhost:28983/solr</a>

<span id="importing-data">**RecordManager & Importing Data**</span>: Set to default, the provisioning phase will install a sample dataset to the local index. It is recommended to use your own data. The easiest way is to add a data file and a proper datasources.ini file to the _data/_ directory + adjust the RECMAN_SOURCE, RECMAN_DATASOURCE & RECMAN_DATA variables in ubuntu-/alma.conf prior to the `vagrant up` command. It is also possible to change the RECMAN_IMPORT to _false_ and set up data harvesting after installation. For more details, see <a href="https://github.com/NatLibFi/RecordManager-Finna/blob/master/conf/datasources.ini.sample">datasources.ini.sample</a> and <a href="https://github.com/NatLibFi/RecordManager/wiki/Usage">RecordManager Usage</a>.
- <a href="https://github.com/NatLibFi/RecordManager/wiki">RecordManager Wiki</a> for additional information.

#### Useful Commands
* `vagrant reload`
  - reload the configuration changes made to _VagrantConf.rb_ file
* `vagrant suspend`
  - freeze the virtual machine, continue with `vagrant resume`
* `vagrant halt`
  - shut down the virtual machine, restart with `vagrant up --no-provision`
* `vagrant destroy`
  - delete the virtual machine
* `vagrant ssh`
  - login to the running virtual machine (vagrant:vagrant) e.g. to restart Apache `sudo service apache2 restart` or to check Apache logs `sudo tail -f /var/log/apache2/error.log`, `sudo tail -f /var/log/apache2/access.log`
  - use option `-c` to run commands in guest via ssh e.g.

    `vagrant ssh -c "less2css"` to compile less to css, or
    
    `vagrant ssh -c "eslint-finna"` to run eslint, or
    
    `vagrant ssh -c "sudo service apache2 restart"` to restart Apache etc.
* `vagrant ssh -c "neofetch"`
  - VM system info
* `vagrant port`
  - see all forwarded ports
* `vagrant box update`
  - update the cached boxes if newer versions exist
* `vagrant box list`
  - show the cached box files, delete unnecessary ones with `vagrant box remove` or `vagrant box prune` (add `-h` for help) e.g.
  
    `vagrant box remove ubuntu/jammy64 --box-version 20221027.0.0`
* `vagrant plugin install vagrant-vbguest`
  - for prolonged use, install <a href="https://github.com/dotless-de/vagrant-vbguest">vagrant-vbguest</a> plugin to keep the host machines's VirtualBox Guest Additions automatically updated
* ( `vagrant package --output ubuntu_vufind2.box`
  - package the virtual machine as a new base box, roughly 700MB or more - the _VagrantConf.rb_ file needs to be edited to use the created box file. )

When addressing the _alma_ machine, just add `alma` at the end of each command.

<a href="https://docs.vagrantup.com/v2/cli/index.html">Vagrant documentation</a> for more info.

### Email Testing Environment
Testing exists only in the _ubuntu_ VM.

- ubuntu.conf:
  >[EMAIL_TEST_ENV](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/ubuntu.conf.sample#L45)=true
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
- run `vagrant ssh -c "due_date_reminders"`
#### Scheduled Alerts
- in user profile add the email address to receive the messages, if not already set
- save a search or two, in Saved searched set the Alert schedule
- run `vagrant ssh -c "scheduled_alerts"`

The email address in user profile should receive the messages. Note that another test user needs to be set up to run the made-up scheduled alerts again - turning them off and back on _might_ work but this is untested. 

### Unit Tests

Unit tests can be run in the _ubuntu_ VM if needed - this might come handy especially if developing upstream to <a href="https://github.com/vufind-org/vufind">vufind.org repository</a>.

A quick example of running a single test (adjust params as needed):  
`vagrant ssh -c "./phing.sh phpunitfaster -Dphpunit_extra_params=/vufind2/module/VuFindConsole/tests/unit-tests/src/VuFindTest/Command/ScheduledSearch/NotifyCommandTest.php"`

For more possibilities see [Using Phing](https://vufind.org/wiki/development:testing:unit_tests#using_phing) in the <a href="https://vufind.org/wiki/development">VuFind Developer Manual</a>.

### Troubleshooting

1. Check the network connection is working. The virtual environment needs to load from several Internet resources and cannot build itself properly without them. Note that there might also be problems with the cloud resources themselves.

2. As NDL-VuFind2 is being actively developed some new settings and configuration options will be presented in its _.ini/yaml/json.sample_ files from time to time. While building the virtual machine these files are only copied if previous ones don't already exist. Therefore should problems arise there might be need to make a backup of the _.ini/yaml/json_ files in _local/config/vufind/_ & _local/config/finna/_ before deleting all of them (not the _.sample_ ones!). The files will then be copied anew next time the virtual machine is succesfully build. If needed, the old settings can now be carried over manually from the backups.  
**A telltale sign of this is usually when the ubuntu machine fails to function properly or the PHP server crashes while the alma machine is working properly** (if built).  
If all else fails, set LOCAL_CACHE_CLEAR to _true_ in _ubuntu.conf_ to clear local cache files during the virtual machine provisioning. Remember to set this back to _false_ to avoid clearing the cache every consecutive time the _ubuntu_ VM is being built.

3. The Ubuntu basebox may be updated quite regularly so after `vagrant box update` it is not very common but quite possible that something breaks in the install scripts. If this happens and items 1 & 2 are already ruled out, run `vagrant up 2>&1 | tee ./vagrant-log.txt` with the default ubuntu.conf settings + create an issue describing shortly what happened and include the logfile.

4. "Cannot shutdown/remove VM - HELP!"  
Often (but not always) it is possible to use the VirtualBox GUI to remove the troublesome VM.  
If this is not the case try VBoxManage:
- Find the name (or ID) of the VM you want to remove:  
`VBoxManage list vms`  
- Shutdown the VM:  
`VBoxManage startvm NAME(OR ID) --type emergencystop`
- Delete the VM:  
`VBoxManage unregistervm NAME(OR ID) --delete`

5. "Library not loaded: '/opt/vagrant/embedded/lib/libssh2.1.dylib' ... '/usr/lib/libssh2.1.dylib' (no such file)" or similar error on `vagrant` commands after upgrading macOS and/or XCode when Vagrant installed via Homebrew  
- Try reinstalling Vagrant:  
`brew reinstall --cask vagrant`

### Known Issues
- If running Solr, [VirtualMemory](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/VagrantConf.rb.sample#L23) needs to be at least around 2048, which should work. Add more if/when needed considering the host has what to spare.
- Antiquated software versions have issues e.g. Vagrant v1.8.7 (_curl_ issues), VirtualBox v5.0.28 & v5.1.8 (_Composer_ issues), maybe others. Use current versions!
- Performance might be slightly slower than native LAMP/MAMP/WAMP but shouldn't be an issue. YMMV though, so worst case, try adding more [VirtualMemory](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/VagrantConf.rb.sample#L23) and/or raising [VirtualCPUs](https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/VagrantConf.rb.sample#L27) to _2_ in _VagrantConf.rb_.<br>
  More speed can also be gained by enabling <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a>:
  - Set <a href="https://github.com/NatLibFi/NDL-VuFind2-Vagrant/blob/master/VagrantConf.rb.sample#L31">EnableNFS</a> to _true_.
  - Mac users, with NFS enabled Vagrant needs to modify _/etc/exports_ and admin password will be asked at every `vagrant up` & `vagrant destroy` unless you once run `sudo scripts/nfs-sudoers_mac.sh` or manually modify sudoers. See <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a> for more information.  
    Using VB v6.1.x, NFS will most likely be difficult to get working correctly. See <a href="https://github.com/hashicorp/vagrant/blob/80e94b5e4ed93a880130b815329fcbce57e4cfed/website/pages/docs/synced-folders/nfs.mdx#troubleshooting-nfs-issues">here</a> and <a href="https://github.com/hashicorp/vagrant/issues/11555">here</a> for NFS troubleshooting. If NFS is absolutely needed and v7.x.x is not an option and nothing else works, use the latest VB <a href="https://www.virtualbox.org/wiki/Download_Old_Builds_6_0">v6.0.x</a>.
  - Linux users, NFS must be used with libvirt provider. To avoid being asked for credentials at every `vagrant up` & `vagrant destroy` either manually modify sudoers or run `sudo scripts/nfs-sudoers_ubuntu.sh` or `sudo scripts/nfs-sudoers_fedora.sh` based on your platform. Please see <a href="https://www.vagrantup.com/docs/synced-folders/nfs.html">NFS</a> for details.
  - Windows users may want to try [Vagrant WinNFSd](https://github.com/winnfsd/vagrant-winnfsd) as by default NFS synced folders are ignored by Vagrant - yet again, this is untested!
- On macOS, VirtualBox v6.1.x is known also to have some permission issues on occasion. Make sure you have given full disk access to Terminal in _System Prefences > Security & Privacy > Privacy_ (also check for relevant programs if using e.g. iTerm2 or integrated terminal in VSCode etc.).
- Apple M1/M2 CPU users should use QEMU provider, which is limited to SMB sharing or RSync. VirtualBox [developer preview](https://www.virtualbox.org/wiki/Downloads) for Apple silicon may work but is untested.
- QEMU provider ignores high-level network configurations and causes a conflict with SSH port forwarding if _ubuntu_ & _alma_ VMs are tried to be run simultaneously. Other providers shouldn't have this limitation given the host has enough resources.
- QEMU and libvirt providers may prompt to destroy both VMs at `vagrant destroy` even when the other one is not running. If this is confusing, target the wanted VM using `vagrant destroy ubuntu` or `vagrant destroy alma`.
- SMB sharing will first ask sudo password and later user credentials at `vagrant up`. User credentials are also asked at `vagrant destroy`.
- Running on Linux has been tested to work with Linux Mint so Ubuntu(/Debian) based distros should likely work, others are unknown.
- For those about to use Windows, we salute you! And best of luck–you tread the unwalked path.

### Resources
- [NDL-VuFind2](https://github.com/NatLibFi/NDL-VuFind2)
- [finna-solr](https://github.com/NatLibFi/finna-solr)
- [RecordManager-Finna](https://github.com/NatLibFi/RecordManager-Finna) & [RecordManager Wiki](https://github.com/NatLibFi/RecordManager/Wiki)
- [finna-ui-components](https://github.com/NatLibFi/finna-ui-components)
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- [QEMU](https://www.qemu.org/)
- [libvirt](https://libvirt.org/)
- [Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)
- [Ubuntu](https://ubuntu.com/)
- [AlmaLinux OS](https://almalinux.org/)
- [Vagrant Cloud](https://app.vagrantup.com/boxes/search)
- [Responsively.app](https://responsively.app/)
- [VuFind](https://vufind.org)
