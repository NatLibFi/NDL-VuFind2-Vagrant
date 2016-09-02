# -*- mode: ruby -*-
# vi: set ft=ruby :

# make sure the vufind2 folder exists
case ARGV[0]
when "up", "up ubuntu"
  if !(File.exists?('../vufind2'))
    puts "vufind2 directory DOES NOT EXIST!"
  end
else
  # do nothing
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Ubuntu config, (default) 'vagrant up'
  config.vm.define "ubuntu", primary: true do |ubuntu|
    # Every Vagrant development environment requires a box. You can search for
    # boxes at https://atlas.hashicorp.com/search.
    ubuntu.vm.box = "ubuntu/trusty64"
    # An example to use instead if you repackage a local custom base box 
    # ubuntu.vm.box = "ubuntu_vufind2 file:./ubuntu_vufind2.box"

    # Create a forwarded port mapping
    ubuntu.vm.network "forwarded_port", guest: 80, host: 8081
    ubuntu.vm.network "forwarded_port", guest: 8983, host: 18983

    # Share an additional folder to the guest VM.
    ubuntu.vm.synced_folder "../vufind2", "/vufind2"

    # Share the cache folder and allow guest machine write access
    ubuntu.vm.synced_folder "../vufind2/local/cache", "/vufind2/local/cache",
      owner: "www-data", group: "www-data",
      :mount_options => ["dmode=777","fmode=666"]

    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    ubuntu.vm.provision :shell, path: "bootstrap_ubuntu.sh"

    # Message to show after provisioning
    ubuntu.vm.post_up_message = "
NDL-VuFind2 installation FINISHED!"
  end

  # CentOS 6 config, 'vagrant up centos'
  config.vm.define "centos", autostart: false do |centos|
    # Every Vagrant development environment requires a box. You can search for
    # boxes at https://atlas.hashicorp.com/search.
    centos.vm.box = "geerlingguy/centos6"
    # An example to use instead if you repackage a local custom base box 
    # centos.vm.box = "centos_vufind2 file:./centos_vufind2.box"

    # Create a forwarded port mapping
    centos.vm.network "forwarded_port", guest: 80, host: 8082
    centos.vm.network "forwarded_port", guest: 8983, host: 28983

    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    centos.vm.provision :shell, path: "bootstrap_centos.sh"

    # Message to show after provisioning
    centos.vm.post_up_message = "
NDL-VuFind2 installation FINISHED!

DO NOT FORGET to SET A PASSWORD for the MySQL root USER!
Also, please remove 'anonymous' user & test databases.

To do both of the above:
- Access the virtual machine first: 'vagrant ssh centos'
- Then run: '/usr/bin/mysql_secure_installation'"
  end

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8081

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true
  
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
    # vb.cpus = 2
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
