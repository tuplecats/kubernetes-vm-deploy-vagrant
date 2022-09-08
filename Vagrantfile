# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'
MasterEnd = 3
Workers = 3

Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.
  config.vm.provision "file", source: "./scripts", destination: "/tmp/scripts"

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.define "loadbalancer" do |lb|
    lb.vm.box = "bento/ubuntu-20.04"
    lb.vm.hostname = "haproxy.kube.lan"
    lb.vm.network "private_network", ip: "172.16.16.100"
    lb.vm.provision "shell", path: "scripts/balancer.sh"
    lb.vm.provider "virtualbox" do |v|
      v.name = "loadbalancer"
      v.memory = 1024
      v.cpus = 2
    end
  end

  # Init workers
  (1..Workers).each do |i|
    config.vm.define "kube-worker#{i}" do |masternode|
      masternode.vm.box = "bento/ubuntu-20.04"
      masternode.vm.hostname = "worker#{i}.kube.lan"
      masternode.vm.provision "shell", path: "scripts/bootstrap.sh"
      masternode.vm.network "private_network", ip: "172.16.16.20#{i}"
      masternode.vm.provider "virtualbox" do |v|
        v.name = "kube-worker#{i}"
        v.memory = 2048
        v.cpus = 2
      end
    end
  end

  # Init masters
  (2..MasterEnd).each do |i|
    config.vm.define "kube-master#{i}" do |masternode|
      masternode.vm.box = "bento/ubuntu-20.04"
      masternode.vm.hostname = "master#{i}.kube.lan"
      masternode.vm.provision "shell", path: "scripts/bootstrap.sh", env: {"IP" => "172.16.16.10#{i}"}
      masternode.vm.network "private_network", ip: "172.16.16.10#{i}"
      masternode.vm.provider "virtualbox" do |v|
        v.name = "kube-master#{i}"
        v.memory = 2048
        v.cpus = 2
      end
    end
  end

  # Init admin master
  config.vm.define "kube-master1" do |masternode|
    masternode.vm.box = "bento/ubuntu-20.04"
    masternode.vm.hostname = "master1.kube.lan"
    masternode.vm.provision "shell", path: "scripts/bootstrap-init-master.sh", env: {"IP" => "172.16.16.101"}
    masternode.vm.network "private_network", ip: "172.16.16.101"
    masternode.vm.provider "virtualbox" do |v|
      v.name = "kube-master1"
      v.memory = 2048
      v.cpus = 2
    end
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
