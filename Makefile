.PHONY: lima

LIMA_INSTANCE ?= vz-mantic
VM_TYPE ?= vz
VM_CPUS ?= 4
VM_MEM ?= 4
VM_DISK ?= 50
VM_CONF ?= '.vmType = "$(VM_TYPE)" | .cpus = $(VM_CPUS) | .memory = "$(VM_MEM)GiB" | .arch = "aarch64" | .disk = "$(VM_DISK)GiB" | .ssh.forwardAgent = true'

install: /opt/homebrew/bin/lima /private/etc/sudoers.d/lima /opt/socket_vmnet
	export LIMA_DEFAULT_PATH=/
	limactl start --name=$(LIMA_INSTANCE) --set=$(VM_CONF) template://vmnet
	$(MAKE) provision clean enter

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
	limactl delete $(LIMA_INSTANCE)

provision:
	limactl shell $(LIMA_INSTANCE) sudo apt list --installed ansible | grep ansible > /dev/null 2>&1 || limactl shell $(LIMA_INSTANCE) sudo apt install ansible
	limactl shell $(LIMA_INSTANCE) ansible-playbook --inventory localhost, -c local -t lima playbook.yml

enter:
	@$(MAKE) enter-lima

enter-lima: up
	@limactl shell --shell /bin/zsh --workdir /home/$(USER).linux/$(LIMA_DEFAULT_PATH) $(LIMA_INSTANCE)

up:
	@limactl list | grep $(LIMA_INSTANCE) | grep Stopped > /dev/null 2>&1 && $(MAKE) start || true

stop:
	limactl stop $(LIMA_INSTANCE)

start:
	ssh-add
	limactl start $(LIMA_INSTANCE)

deploy:
	ansible-playbook -i hosts $(if $(tags),-t $(tags) ,)$(if $(rebuild),-e rebuild=$(rebuild) ,)playbook.yml --vault-password-file secret_vars/.all.txt

config:
	ansible-vault edit secret_vars/all.yml --vault-password-file secret_vars/.all.txt
