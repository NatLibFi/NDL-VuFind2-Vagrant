# -*- mode: ruby -*-
# vi: set ft=ruby :

# make sure the VagrantConf.rb exists
if !(File.exists?('VagrantConf.rb'))
  puts "VagrantConf.rb file DOES NOT EXIST!"
  puts "Copying from VagrantConf.rb.sample as default configuration..."
  File.write('VagrantConf.rb', File.open('VagrantConf.rb.sample').read())
  puts "Please try running the command again!"
  exit
end
require './VagrantConf.rb'
include VagrantConf

# check the forked NDL-VuFind2 folder exists + create conf file if missing
case ARGV[1] 
when nil, "ubuntu"
  if ARGV[0] == "up"
    conf = 'ubuntu.conf'
    sample = conf + '.sample'
    if !(Dir.exists?(VufindPath))
      puts VufindPath + " directory DOES NOT EXIST!"
      puts "Clone/copy the NDL-VuFind2 files & check the path in VagrantConf.rb"
      exit
    end
    if !(File.exists?(conf))
      puts conf + " file DOES NOT EXIST!"
      puts "Copying from " + sample + "..."
      File.write(conf, File.open(sample).read())
      puts "See " + conf + " for changing the defaults and/or try again!"
      exit
    end
  end
when "centos"
  if ARGV[0] == "up"
    conf = 'centos.conf'
    sample = conf + '.sample' 
    if !(File.exists?(conf))
      puts conf + " file DOES NOT EXIST!"
      puts "Copying from " + sample + "..."
      File.write(conf, File.open(sample).read())
      puts "See " + conf + " for changing the defaults and/or try again!"
      exit
    end
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
    ubuntu.vm.box = UbuntuBox
    # An example to use instead if you repackage a local custom base box 
    # ubuntu.vm.box = "ubuntu_vufind2 file:./ubuntu_vufind2.box"

    # Create a forwarded port mapping
    ubuntu.vm.network "forwarded_port", guest: 80, host: 8081,
    auto_correct: true
    ubuntu.vm.network "forwarded_port", guest: 8983, host: 18983,
    auto_correct: true
    ubuntu.vm.network "forwarded_port", guest: 3033, host: 3033,
    auto_correct: true
    ubuntu.vm.network "forwarded_port", guest: 36000, host: 36000,
    auto_correct: true
    
    # Share additional folders to the guest VM.
  if RUBY_PLATFORM =~ /darwin/ && EnableNFS
    ubuntu.vm.network "private_network", type: "dhcp"
    ubuntu.vm.synced_folder VufindPath, MountPath, type: "nfs"
    if defined?(RMMountPath)
      ubuntu.vm.synced_folder RMPath, RMMountPath, type: "nfs"
    end
  else
    ubuntu.vm.synced_folder VufindPath, MountPath
    if defined?(RMMountPath)
      ubuntu.vm.synced_folder RMPath, RMMountPath
    end
  end

    # Share the cache folder and allow guest machine write access
  case VMProvider
  when "virtualbox"
    ubuntu.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
      owner: "www-data", group: "www-data",
      :mount_options => ["dmode=777","fmode=666"]
  when "hyperv"
    ubuntu.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
      owner: "www-data", group: "www-data",
      :mount_options => ["dir_mode=777","file_mode=666"]
  when "vmware_desktop"
    ubuntu.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
      owner: "www-data", group: "www-data",
      # umask might not give all permissions needed for some directories
      umask: "666"
  end

    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    ubuntu.vm.provision :shell, path: "scripts/ubuntu_bootstrap.sh"

    # Message to show after provisioning
    ubuntu.vm.post_up_message = "Virtual machine installation FINISHED!"
  end

  # CentOS config, 'vagrant up centos'
  config.vm.define "centos", autostart: false do |centos|
    # Every Vagrant development environment requires a box. You can search for
    # boxes at https://atlas.hashicorp.com/search.
    centos.vm.box = CentosBox
    # An example to use instead if you repackage a local custom base box 
    # centos.vm.box = "centos_vufind2 file:./centos_vufind2.box"

    # Create a forwarded port mapping
    centos.vm.network "forwarded_port", guest: 80, host: 8082
    centos.vm.network "forwarded_port", guest: 8983, host: 28983

    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    centos.vm.provision :shell, path: "scripts/centos_bootstrap.sh"

    # Message to show after provisioning
    centos.vm.post_up_message = "
Virtual machine installation FINISHED!

DO NOT FORGET to SET A PASSWORD for the MariaDB root USER!
Also, please remove 'anonymous' user & test databases.

To do both of the above:
- Access the virtual machine first: 'vagrant ssh centos'
- Then run: '/usr/bin/mysql_secure_installation'"
  end

  config.trigger.after :up,
    info: "All provisioning done! SYSTEM INFO:",
    run_remote: {inline: "neofetch"}

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
  config.vm.provider VMProvider do |v|

    # Settings depending on the VM Provider    
    if VMProvider == "hyperv"
      # Display the VM Provider GUI when booting the machine
      v.gui = VMProviderGUI
    end
    if VMProvider == "virtualbox"
      # Check for VirtualBox Guest Additions
      v.check_guest_additions = CheckGuestAdditions    
    end
    # Customize the amount of memory and cpus on the VM:
    if VMProvider != "vmware_desktop"
      v.memory = VirtualMemory
      v.cpus = VirtualCPUs
    else
      v.vmx["memsize"] = VirtualMemory
      v.vmx["numvcpus"] = VirtualCPUs
    end
    
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
