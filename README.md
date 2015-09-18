# NDL-VuFind2-Vagrant
Vagrant setup for NDL VuFind2

Requirements
------------
- <a href="https://www.virtualbox.org">VirtualBox</a>
- <a href="https://www.vagrantup.com">Vagrant</a>
- NDL-VuFind2 (with a working configuration)

Set-up
------
Put the files in a directory parallel to the NDL-VuFind2 working directory e.g. <path-to>/vufind2 & <same-path-to>/vagrant_vufind2.

Use
---
'vagrant up' (this will take a few minutes so enjoy your beverage of choice)

Point your browser to http://localhost:8081

Known Issues
------------
- Slower than native LAMP/MAMP.
- Copying the vufind2/local directory inside the virtual machine is a dirty hack to get the virtual machine to access local/cache. Any changes under local/config/ in the host need to be either copied to the virtual machine manually or running the provisioning with 'vagrant provision' (or raising the virtual machine again with 'vagrant destroy' & 'vagrant up'). 
