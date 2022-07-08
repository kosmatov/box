.PHONY: lima

enter:
	(vagrant status | grep running && vagrant ssh) || make box_up

box_up: up mount
	ssh-add

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

deploy:
	ansible-playbook -i hosts $(if $(tags),-t $(tags) ,)$(if $(rebuild),-e rebuild=$(rebuild) ,)playbook.yml --skip-tags vagrant --vault-password-file secret_vars/.all.txt

lima:
	lima dnf list --installed epel-release || lima sudo dnf install epel-release
	lima sudo dnf update
	lima dnf list --installed ansible || lima sudo dnf install ansible
	lima ansible-playbook --inventory localhost, -c local -t lima playbook.yml --skip-tags vagrant

config:
	ansible-vault edit secret_vars/all.yml --vault-password-file secret_vars/.all.txt
