LIMA_INSTANCE ?= vz-ora
VM_TYPE ?= vz
VM_CPUS ?= 8
VM_MEM ?= 8
VM_DISK ?= 100
VM_CONF ?= '.vmType = "$(VM_TYPE)" | .cpus = $(VM_CPUS) | .memory = "$(VM_MEM)GiB" | .arch = "aarch64" | .disk = "$(VM_DISK)GiB" | .ssh.forwardAgent = true'

lima: /opt/homebrew/bin/lima /opt/socket_vmnet
	export LIMA_DEFAULT_PATH=/
	limactl sudoers
	limactl create --network=lima:shared --name=$(LIMA_INSTANCE) --set=$(VM_CONF) template://default
	limactl start $(LIMA_INSTANCE)
	$(MAKE) lima-provision lima-clean lima-enter

local: local-provision

/opt/homebrew/bin/lima:
	brew install lima

/opt/socket_vmnet:
	brew install socket_vmnet
	sudo mkdir -p /opt/socket_vmnet/
	sudo cp -R /opt/homebrew/opt/socket_vmnet/* /opt/socket_vmnet/

/private/etc/sudoers.d/lima:
	limactl sudoers > etc_sudoers.d_lima
	sudo install -o root etc_sudoers.d_lima /private/etc/sudoers.d/lima

lima-clean:
	[ -e etc_sudoers.d_lima ] && rm etc_sudoers.d_lima

lima-destroy:
	limactl delete $(LIMA_INSTANCE)

lima-provision:
	limactl shell $(LIMA_INSTANCE) sudo apt-get update
	limactl shell $(LIMA_INSTANCE) sudo apt list --installed ansible | grep ansible > /dev/null 2>&1 || limactl shell $(LIMA_INSTANCE) sudo apt-get -y install ansible
	limactl shell $(LIMA_INSTANCE) ansible-playbook --inventory localhost, -c local -t lima playbook.yml

local-provision: /opt/homebrew/bin/ansible-playbook
	ansible-playbook --inventory localhost, -c local playbook.yml

/opt/homebrew/bin/ansible-playbook:
	brew install ansible

enter:
	@[ -f /opt/homebrew/bin/lima ] && make lima-enter || true

lima-enter: lima-up
	@limactl shell --shell /bin/zsh --workdir /home/$(USER).linux/$(LIMA_DEFAULT_PATH) $(LIMA_INSTANCE)

lima-up:
	@limactl list | grep $(LIMA_INSTANCE) | grep Stopped > /dev/null 2>&1 && make start || true

lima-stop:
	limactl stop $(LIMA_INSTANCE)

lima-start:
	limactl start $(LIMA_INSTANCE)

stop:
	@[ -f /opt/homebrew/bin/lima ] && make lima-stop || true

start:
	ssh-add
	@[ -f /opt/homebrew/bin/lima ] && make lima-start || true

deploy:
	ansible-playbook -i hosts $(if $(tags),-t $(tags) ,)$(if $(rebuild),-e rebuild=$(rebuild) ,)playbook.yml --vault-password-file secret_vars/.all.txt

config:
	ansible-vault edit secret_vars/all.yml --vault-password-file secret_vars/.all.txt
