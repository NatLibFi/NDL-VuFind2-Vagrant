# -*- mode: ruby -*-
# vi: set ft=ruby :

# make sure the VagrantConf.rb exists
if !(File.exists?('VagrantConf.rb'))
  puts "VagrantConf.rb file DOES NOT EXIST!"
  puts "Copying from VagrantConf.rb.sample as default configuration..."
  File.write('VagrantConf.rb', File.open('VagrantConf.rb.sample').read())
  puts "See VagrantConf.rb for changing the defaults and/or try running the command again!"
  exit
end
require './VagrantConf.rb'
include VagrantConf

# check the forked NDL-VuFind2 folder exists + create conf file if missing
case ARGV[1] 
when nil, "dev"
  if ARGV[0] == "up"
    conf = 'dev.conf'
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
    if QemuSharing == 'rsync'
      system("scripts/dev_pre-rsync.sh")
    end
  end
when "server"
  if ARGV[0] == "up"
    conf = 'server.conf'
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

# Please see the file VagrantConf.rb for user configurable options.
# There should be no need to change Vagrantfile itself unless you know
# what you are doing!

Vagrant.configure(2) do |config|

  # Dev config, (default) 'vagrant up'
  config.vm.define "dev", primary: true do |dev|
    # Use the correct Dev box
    case VMProvider
    when "virtualbox"
      dev.vm.box = DevBox
    else
      if VMProvider == "qemu" && QemuHostCPU == "arm"
        dev.vm.box = DevBoxARM
      else
        dev.vm.box = DevBoxAlt
      end
    end
    
    # Network settings
    if EnableNFS
      dev.vm.network "private_network", ip: NFSIP
    else
      dev.vm.network "private_network", type: "dhcp"
    end

    # Create the forwarded port mappings
    dev.vm.network "forwarded_port", guest: 80, host: 8081,
    auto_correct: true
    dev.vm.network "forwarded_port", guest: 8983, host: 18983,
    auto_correct: true
    dev.vm.network "forwarded_port", guest: 3033, host: 3033,
    auto_correct: true
    dev.vm.network "forwarded_port", guest: 36000, host: 36000,
    auto_correct: true
    
    # Share additional folders to the guest VM.
    case VMProvider
    when "virtualbox", "libvirt"
      # NFS sharing
      if EnableNFS
        if VMProvider == "libvirt"
          dev.vm.synced_folder ".", "/vagrant", type: "nfs",
            nfs_version: NFSVersion, nfs_udp: NFSUDP
        end
        dev.vm.synced_folder VufindPath, MountPath, type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
        if Dir.exists?(RMPath)
          dev.vm.synced_folder RMPath, RMMountPath, type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
        end
        if Dir.exists?(UICPath)
          dev.vm.synced_folder UICPath, UICMountPath, type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
        end
        if Dir.exists?(AdmIntPath)
          dev.vm.synced_folder AdmIntPath, AdmIntMountPath, type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
        end

        # Share the cache folder and allow guest machine write access
        dev.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache", type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
      # VirtualBox sharing
      else
        if VMProvider == "libvirt"
          puts "NFS needs to be enabled when using libvirt provider. Check your VagrantConf.rb file"
          exit
        end  
        dev.vm.synced_folder VufindPath, MountPath
        if Dir.exists?(RMPath)
          dev.vm.synced_folder RMPath, RMMountPath
        end
        if Dir.exists?(UICPath)
          dev.vm.synced_folder UICPath, UICMountPath
        end
        if Dir.exists?(AdmIntPath)
          dev.vm.synced_folder AdmIntPath, AdmIntMountPath
        end
        # Share the cache folder and allow guest machine write access
        dev.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
          owner: "www-data", group: "www-data",
          :mount_options => ["dmode=777","fmode=666"]
      end
    when "qemu"
      case QemuSharing
      # SMB Sharing
      when "smb"
        dev.vm.synced_folder ".", "/vagrant",
          type: "smb", smb_host: "10.0.2.2"
        dev.vm.synced_folder VufindPath, MountPath,
          type: "smb", smb_host: "10.0.2.2"
        if Dir.exists?(RMPath)
          dev.vm.synced_folder RMPath, RMMountPath,
            type: "smb", smb_host: "10.0.2.2"
        end
        if Dir.exists?(UICPath)
          dev.vm.synced_folder UICPath, UICMountPath,
            type: "smb", smb_host: "10.0.2.2"
        end
        if Dir.exists?(AdmIntPath)
          dev.vm.synced_folder AdmIntPath, AdmIntMountPath,
            type: "smb", smb_host: "10.0.2.2"
        end
        # Share the cache folder and allow guest machine write access
        dev.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
          type: "smb", smb_host: "10.0.2.2",
          owner: "www-data", group: "www-data"
      # RSync sharing 
      when "rsync"
        dev.vm.synced_folder ".", "/vagrant", type: "rsync"
        dev.vm.synced_folder VufindPath, MountPath, type: "rsync",
          rsync__exclude: [
            "/vendor",
            "/local/cache",
            "/local/languages/finna/fi-datasources.ini",
            "/local/languages/finna/sv-datasources.ini",
            "/local/languages/finna/en-gb-datasources.ini",
            "/themes/finna2/css/finna.css"
          ]
        if Dir.exists?(RMPath)
          dev.vm.synced_folder RMPath, RMMountPath, type: "rsync"
        end
        if Dir.exists?(UICPath)
          dev.vm.synced_folder UICPath, UICMountPath, type: "rsync"
        end
        if Dir.exists?(AdmIntPath)
          dev.vm.synced_folder AdmIntPath, AdmIntMountPath, type: "rsync"
        end
        if Vagrant.has_plugin?("vagrant-gatling-rsync")
          dev.vm.gatling.rsync_on_startup = RsyncGatlingAuto
          dev.vm.gatling.latency = RsyncGatlingLatency
          dev.vm.gatling.time_format = RsyncGatlingTimeFormat
        end
      else
        puts "QEMU provider only supports SMB sharing or RSync. Check your VagrantConf.rb file"
        exit
      end
    when "hyperv"
      # SMBv1 needs to be enabled in Windows
      dev.vm.synced_folder ".", "/vagrant",
        type: "smb", smb_host: "10.0.2.2"
      dev.vm.synced_folder VufindPath, MountPath,
        type: "smb", smb_host: "10.0.2.2"
      if Dir.exists?(RMPath)
        dev.vm.synced_folder RMPath, RMMountPath,
          type: "smb", smb_host: "10.0.2.2"
      end
      if Dir.exists?(UICPath)
        dev.vm.synced_folder UICPath, UICMountPath,
          type: "smb", smb_host: "10.0.2.2"
      end
      if Dir.exists?(AdmIntPath)
        dev.vm.synced_folder AdmIntPath, AdmIntMountPath,
          type: "smb", smb_host: "10.0.2.2"
      end
      # Share the cache folder and allow guest machine write access
      dev.vm.synced_folder VufindPath + "/local/cache", MountPath + "/local/cache",
        type: "smb", smb_host: "10.0.2.2",
        owner: "www-data", group: "www-data"
    else
      puts "Unknown provider. Check your VMProvider in VagrantConf.rb file"
      exit
    end

    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    dev.vm.provision :shell, path: "scripts/dev_bootstrap.sh"

    # Message to show after provisioning
    dev.vm.post_up_message = "Virtual machine installation FINISHED!"
  end

  # Server config, 'vagrant up server'
  config.vm.define "server", autostart: false do |server|    
    server.vm.box = ServerBox

    # Create a forwarded port mapping
    server.vm.network "forwarded_port", guest: 80, host: 8082
    server.vm.network "forwarded_port", guest: 8983, host: 28983

    # Share /vagrant folder to the guest VM.
    case VMProvider
    when "virtualbox"
      # nothing to share, /vagrant is handled automatically
      next
    when "libvirt"
      # NFS sharing
      if EnableNFS
        server.vm.synced_folder ".", "/vagrant", type: "nfs",
          nfs_version: NFSVersion, nfs_udp: NFSUDP
      else
        puts "NFS needs to be enabled when using libvirt provider. Check your VagrantConf.rb file"
        exit
      end
    when "qemu"
      case QemuSharing
      # SMB Sharing
      when "smb"
        server.vm.synced_folder ".", "/vagrant",
          type: "smb", smb_host: "10.0.2.2"
      # RSync sharing 
      when "rsync"
        server.vm.synced_folder ".", "/vagrant", type: "rsync"
      else
        puts "QEMU provider only supports SMB sharing or RSync. Check your VagrantConf.rb file"
        exit
      end
    when "hyperv"
      # SMBv1 needs to be enabled in Windows
      server.vm.synced_folder ".", "/vagrant",
        type: "smb", smb_host: "10.0.2.2"
    else
      puts "Unknown provider. Check your VMProvider in VagrantConf.rb file"
      exit
    end
      
    # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
    server.vm.provision :shell, path: "scripts/server_bootstrap.sh"

    # Message to show after provisioning
    server.vm.post_up_message = "
Virtual machine installation FINISHED!

DO NOT FORGET to SET A PASSWORD for the MySQL/MariaDB root USER!
Also, please remove 'anonymous' user & test databases.

To do both of the above:
- Access the virtual machine first: 'vagrant ssh server'
- Then run: '/usr/bin/mysql_secure_installation'"
  end

  config.trigger.after :up,
    info: "All provisioning done! SYSTEM INFO:",
    run_remote: {inline: "neofetch"}

  # Provider-specific configuration so you can fine-tune various.
  # Any changes needed should be done in VagrantConf.rb
  #
  config.vm.provider VMProvider do |v|
    # Settings depending on the VM Provider    
    case VMProvider
    when "virtualbox"
      # Display the VM Provider GUI when booting the machine
      v.gui = VMProviderGUI
      # Check for VirtualBox Guest Additions
      v.check_guest_additions = CheckGuestAdditions
    when "qemu"
      v.ssh_port = QemuSSHPort
      v.cpu = QemuCPU
      v.smp = QemuSmpArgs
      case QemuHostCPU
      when "intel"
        v.arch = QemuArchIntel
        v.machine = QemuMachineIntel
        v.net_device = QemuNetDeviceIntel
        v.qemu_dir = QemuDirIntel
      when "arm"
        v.arch = QemuArchARM
        v.machine = QemuMachineARM
        v.net_device = QemuNetDeviceARM
        v.qemu_dir = QemuDirARM
      end
    end

    # The amount of memory and cpus on the VM:
    v.memory = VirtualMemory
    v.cpus = VirtualCPUs
  end

end
