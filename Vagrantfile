Vagrant.configure("2") do |config|
  #config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "ubuntu/focal64"
  config.vm.box = "ubuntu/jammy64"
  config.vm.provider :virtualbox do |vb|
    #vb.gui = true
    #vb.memory = 2048
    vb.memory = 4096
    vb.cpus = 4
  end
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision :shell, inline: <<-SHELL
  sudo -u vagrant -i sudo apt-get update
  sudo -u vagrant -i sudo apt-get install -y make
  sudo -u vagrant -i make -C /vagrant clean install
  sudo -u vagrant -i make -C /vagrant sample
  SHELL
end
