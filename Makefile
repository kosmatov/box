.PHONY: lima

install: /opt/homebrew/bin/lima /private/etc/sudoers.d/lima /opt/socket_vmnet
	export LIMA_DEFAULT_PATH=/
	limactl start --name=default
	make provision clean enter

/opt/homebrew/bin/lima:
	brew install lima

/opt/socket_vmnet:
	brew isntall socket_vmnet
	sudo cp -R /opt/homebrew/opt/socket_vmnet /opt/socket_vmnet

/private/etc/sudoers.d/lima:
	limactl sudoers > etc_sudoers.d_lima
	sudo install -o root etc_sudoers.d_lima /private/etc/sudoers.d/lima

clean:
	[ -e etc_sudoers.d_lima ] && rm etc_sudoers.d_lima

destroy:
	limactl delete default

provision:
	lima apt list --installed ansible | grep ansible > /dev/null 2>&1 || lima sudo apt install ansible
	lima ansible-playbook --inventory localhost, -c local -t lima playbook.yml

enter:
	@make enter-lima

enter-lima: up
	@limactl shell --shell /bin/zsh --workdir /home/$(USER).linux/$(LIMA_DEFAULT_PATH) default nvim

up:
	@limactl list | grep default | grep Stopped > /dev/null 2>&1 && make start || true

stop:
	limactl stop default

start:
	ssh-add
	limactl start default

deploy:
	ansible-playbook -i hosts $(if $(tags),-t $(tags) ,)$(if $(rebuild),-e rebuild=$(rebuild) ,)playbook.yml --vault-password-file secret_vars/.all.txt

config:
	ansible-vault edit secret_vars/all.yml --vault-password-file secret_vars/.all.txt
