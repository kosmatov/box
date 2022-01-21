enter:
	(vagrant status | grep running && vagrant ssh) || make box_up

box_up: up mount
	ssh-add
	vagrant ssh

up:
	vagrant up

mount: vagrant-home
	df | grep vagrant || sudo mount -t nfs -o resvport,rw,soft 192.168.56.13:/home/vagrant ~/vagrant-home/

umount:
	diskutil unmount ~/vagrant-home

vagrant-home:
	mkdir -p ~/vagrant-home

halt: umount
	vagrant halt
