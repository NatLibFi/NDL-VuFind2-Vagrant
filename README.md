# NDL-VuFind2-Vagrant
Vagrant setup for NDL VuFind2

Requirements
------------
- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- <a href="https://github.com/NatLibFi/NDL-VuFind2">NDL-VuFind2</a> (with a working configuration)

Set-up
------
Put the files in a directory parallel to the NDL-VuFind2 working directory e.g. path-to/vufind2 & same-path-to/vagrant_vufind2.

Use
---
'vagrant up' (this will take a few minutes so enjoy your beverage of choice)

Point your browser to http://localhost:8081

Other useful commands:
* 'vagrant reload' - reloads the configuration changes made to Vagrantfile.
* 'vagrant halt' - shuts down the virtual machine, restart with 'vagrant up'
* 'vagrant destroy'  - deletes the virtual machine along with any cached box files etc.

Known Issues
------------
- Slower than native LAMP/MAMP. You can try adding more v.memory/v.cpus in Vagrantfile.
- Copying the vufind2/local directory inside the virtual machine is a dirty hack to get the virtual machine to access local/cache. Any changes under local/config/ in the host need to be either copied to the virtual machine manually or running the provisioning with 'vagrant provision' (or building the virtual machine again with 'vagrant destroy' & 'vagrant up'). 
- Running Solr requires adjusting the the v.memory (2048 should work).
