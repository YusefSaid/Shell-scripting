Vagrant.configure("2") do |config|
  # Debian Bookworm
  config.vm.define "debian" do |debian|
    debian.vm.box = "debian/bookworm64"
    debian.vm.hostname = "debian-vm"
    debian.vm.network "private_network", type: "dhcp"
    debian.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end

  # AlmaLinux 9
  config.vm.define "almalinux" do |alma|
    alma.vm.box = "almalinux/9"
    alma.vm.hostname = "almalinux-vm"
    alma.vm.network "private_network", type: "dhcp"
    alma.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end

  # Alpine Linux 3.19
  config.vm.define "alpine" do |alpine|
    alpine.vm.box = "generic/alpine319"
    alpine.vm.hostname = "alpine-vm"
    alpine.vm.network "private_network", type: "dhcp"
    alpine.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
    alpine.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  end
end
