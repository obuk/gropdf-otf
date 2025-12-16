Vagrant.configure("2") do |config|
  #config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "ubuntu/focal64"
  #config.vm.box = "ubuntu/jammy64"
  config.vm.box = "bento/ubuntu-22.04"
  #config.vm.box = "bento/ubuntu-24.04"
  config.vm.provider :virtualbox do |vb|
    #vb.gui = true
    #vb.memory = 2048
    vb.memory = 4096
    vb.cpus = 4
  end
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision :shell, inline: <<-SHELL
  # 1. setup system-wide default paper size
  echo a4 > /tmp/papersize
  sudo install -m644 /tmp/papersize /etc
  # 2. install the minimum packages for building
  sudo apt-get update --fix-missing
  sudo apt-get install -y build-essential
  # 3. make plenv and pyenv before anthing else.
  sudo -u vagrant -i make -C /vagrant clean plenv pyenv
  # 4. make everything. make clean is not required,
  # but it doesn't significantly increase make time.
  sudo -u vagrant -i make -C /vagrant clean install
  # 5. make pdf sample
  sudo -u vagrant -i make -C /vagrant GROPDF_DEBUG=--opt=5 gropdf-otf.7.pdf
  #sudo -u vagrant -i make -C /vagrant sample
  SHELL
end
