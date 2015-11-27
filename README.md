### NDL-VuFind2-Vagrant
Vagrant setup for NDL VuFind2 with two separate virtual machines:
- **ubuntu** (default)
  - for development, uses working files from the host's filesystem
- **centos**
  - a testbed to build a personal test server; SELinux enabled so could maybe even be a rough outline to set-up a production server, who knows

If you need the Oracle Instant Client (for eg. Voyager) see the <a href="https://github.com/tmikkonen/NDL-VuFind2-Vagrant/tree/PHP-OCI_Oracle">PHP-OCI_Oracle</a> branch.

#### Requirements

- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.vagrantup.com">Vagrant</a>

_ubuntu_:
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (fork it!) cloned to the host computer
  - with a working configuration - for the minimum, either import some data to Solr or change the config to use a remote Solr URL (like the NDL development index - for limited users only).

#### Set-up

See the bootstrap files for possible config changes prior to running the VMs.

_ubuntu_:

Put the files in a directory parallel to the NDL-VuFind2 working directory e.g. _path-to/vufind2_ & _same-path-to/vagrant_vufind2_. If the working directory is other than _vufind2_, modify the _Vagrantfile_ accordingly.

_centos_:

If only using _centos_, any directory with sufficent user permissions will do. If using both, the _ubuntu_ directory is fine.

#### Use

_ubuntu_:
- 'vagrant up'
  - This will take a few minutes, so enjoy your beverage of choice!
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

**Import data**: put the file(s) (eg. _data.xml_) into the same host directory, ssh into the VM and use an import script in _/usr/local/vufind2_ e.g. '/usr/local/vufind2/import-marc.sh /vagrant/data.xml'

**Solr**: '/usr/local/vufind2/vufind.sh start/stop/restart' inside the VM to control the running state (use without attributes to see all options).

#### Useful commands
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
- Copying the _vufind2/local_ directory inside the virtual machine is a ~~dirty~~ hack to get the virtual machine to access _local/cache_. However, the changes in the host under _local/config/_ are now rsynced automatically to the virtual machine. If for some reason they are not, run 'vagrant rsync-auto'. The rsyncing comes with the slight caveat for Windows users who need to download <a href="http://www.rsync.net/resources/binaries/cwRsync_5.4.1_x86_Free.zip">rsync</a> and install it with the default options
- If running Solr, v.memory needs to be at least around 2048, which should work.
