VM_TYPE ?= vz
VM_CPUS ?= 8
VM_MEM ?= 8
VM_DISK ?= 100
LIMA_INSTANCE ?= ora
VM_CONF ?= '.cpus = $(VM_CPUS) | .memory = "$(VM_MEM)GiB" | .disk = "$(VM_DISK)GiB" | .ssh.forwardAgent = true | .containerd.system = false | .containerd.user = false'
ifeq ($(VM_TYPE),vz)
	VM_ARGS ?= --rosetta --mount-type=virtiofs
else
	LIMA_INSTANCE := amd64-$(LIMA_INSTANCE)
	VM_ARGS ?= --arch=x86_64
endif

lima: /opt/homebrew/bin/lima /opt/homebrew/bin/qemu
	LIMA_DEFAULT_PATH=/ limactl create \
		--name=$(LIMA_INSTANCE) \
		$(VM_ARGS) \
		-- mount-writable=yes
		--set=$(VM_CONF) \
		template://ubuntu
	limactl start $(LIMA_INSTANCE)
	make lima-provision lima-clean lima-stop lima-enter

local: local-provision

/opt/socket_vmnet: /private/etc/sudoers.d/lima
ifneq ($(VM_TYPE),vz)
	brew install socket_vmnet
	sudo mkdir -p /opt/socket_vmnet/
	sudo cp -R /opt/homebrew/opt/socket_vmnet/* /opt/socket_vmnet/
endif

/private/etc/sudoers.d/lima:
ifneq ($(VM_TYPE),vz)
	limactl sudoers > etc_sudoers.d_lima
	sudo install -o root etc_sudoers.d_lima /private/etc/sudoers.d/lima
endif

/opt/homebrew/bin/qemu: /opt/socket_vmnet
ifneq ($(VM_TYPE),vz)
	brew install qemu
endif

lima-clean:
	[ -e etc_sudoers.d_lima ] && rm etc_sudoers.d_lima || true

/opt/homebrew/bin/lima:
	brew install lima

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
