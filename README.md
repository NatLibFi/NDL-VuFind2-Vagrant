# NDL-VuFind2-Vagrant
Vagrant setup for NDL VuFind2

Requirements
------------
- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (with a working configuration - for the minimum, change the config to use the NDL development index URL)

Set-up
------
Put the files in a directory parallel to the NDL-VuFind2 working directory e.g. path-to/vufind2 & same-path-to/vagrant_vufind2. If the working directory is other than vufind2, modify the Vagrantfile accordingly.

Use
---
'vagrant up' (this will take a few minutes so enjoy your beverage of choice)

Point your browser to <a href="http://localhost:8081">http://localhost:8081</a>

(Blank page or errors, adjust the config(s) & run 'vagrant provision', reload browser page.)

Useful commands
---------------
* 'vagrant reload' - reloads the configuration changes made to Vagrantfile.
* 'vagrant halt' - shuts down the virtual machine, restart with 'vagrant up'
* 'vagrant destroy'  - deletes the virtual machine along with any cached box files etc.
* 'vagrant ssh' - login to the running virtual machine (vagrant:vagrant) or e.g. restarting Apache ('sudo service apache2 restart') or checking Apache logs in /var/log/apache2/ (needs root, use 'su')

<a href="https://docs.vagrantup.com/v2/cli/index.html">Vagrant documentation</a> for more info.

Known Issues
------------
- Slower than native LAMP/MAMP. You can try adding more v.memory/v.cpus in Vagrantfile.
- Copying the vufind2/local directory inside the virtual machine is a dirty hack to get the virtual machine to access local/cache. Any changes under local/config/ in the host need to be either copied to the virtual machine manually or running the provisioning with 'vagrant provision' (or building the virtual machine again with 'vagrant destroy' & 'vagrant up'). 
- If running Solr, v.memory needs to be adjusted (2048 should work).
