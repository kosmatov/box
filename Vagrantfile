# -*- mode: ruby -*-
# vi: set ft=ruby :

vminfo = `VBoxManage showvminfo $(VBoxManage list vms | grep rbox | cut -d\{ -f2 | cut -d\} -f1 | head -1)`
home_disk_file = File.expand_path('../VirtualBox VMs/rbox-home.vdi', __dir__)
docker_disk_file = File.expand_path('../VirtualBox VMs/rbox-docker.vdi', __dir__)

Vagrant.configure("2") do |config|
  config.vm.hostname = "rbox"
  config.vm.box = "ubuntu/jammy64"

  config.vm.network :private_network, ip: "192.168.56.13"
  config.vm.network :forwarded_port, guest: 8080, host: 8080

  # config.vm.synced_folder "../", "/host", type: "nfs"

  config.vm.provider :virtualbox do |vb|
    # vb.gui = true
    vb.memory = 2048
    vb.cpus = 4

    # vb.customize ['storagectl', :id, '--name', 'SATA Controller', '--add', 'sata', '--controller', 'IntelAHCI'] if vminfo['SATA Controller'].nil?

    # if vminfo[docker_disk_file].nil?
    #   vb.customize ['createhd', '--filename', docker_disk_file, '--size', 50 * 1024] unless File.exist?(docker_disk_file)
    #   vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', docker_disk_file]
    # end

    # if vminfo[home_disk_file].nil?
    #   vb.customize ['createhd', '--filename', home_disk_file, '--size', 20 * 1024] unless File.exist?(home_disk_file)
    #   vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', home_disk_file]
    # end
  end

  config.vm.provision "ansible" do |an|
    an.playbook = "playbook.yml"
  end

  config.ssh.forward_agent = true
  config.ssh.keep_alive = true
end
