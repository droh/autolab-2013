AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/build/buildlog-$@

all:
	@echo  'IMPORTANT: Run autolab.sh before you do anything else:'
	@echo  '    source autolab.sh'
	@echo
	@echo  'Distribution init and clean:'
	@echo  '    dist_init			- Create necessary dirs and links'
	@echo  '    dist_clean			- Remove all repos and log files'
	@echo  '    dist_update			- Update this package itself in case of correct repo'
	@echo  'Dependencies installation:'
	@echo  '    install_rpyc		- Install RPyC'
	@echo  '    install_tashi		- Install tashi'
	@echo  '    install_qemu		- Install QEMU'
	@echo  'Node operations:'
	@echo  '    node_netinit		- Initialize net config for node'
	@echo  'Tashi operations:'
	@echo  '    tashi_status		- Show tashi status with getHosts and getInstances'
	@echo  '    tashi_stop			- Kill all tashi processes and tmp files'

node_netinit:
	NAME_BR = br2013
	NAME_IF = em2
	@echo  'Add and configure bridge'
	@brctl addbr $(NAME_BR)
	@brctl setfd $(NAME_BR) 1
	@brctl sethello $(NAME_BR) 1
	@ifdown $(NAME_IF)
	@ifconfig $(NAME_IF) 0.0.0.0
	@brctl addif $(NAME_BR) $(NAME_IF)
	@echo  'Change the bridge name in qemu-ifup.0'
	@sed -i "s:NAME_BR:$(NAME_BR):" $(AUTOLAB)/etc/qemu-ifup.0
	@echo  'You must specify IP addr to this host by:'
	@echo  '    ifconfig $(NAME_BR) 192.168.2.xx up'

tashi_status:
	@$(AUTOLAB)/bin/tashi-client getHosts
	@$(AUTOLAB)/bin/tashi-client getInstances

tashi_stop:
	@echo  'Killing all possibly running processes ...'
	@killall -9 clustermanager nodemanager primitive qemu-system-x86_64
	@echo  'Cleaning files in tmp dir, which will affect the next running of tashi'
	@rm -fr $(AUTOLAB)/tmp/*

dist_init:
	@echo  'Create log and tmp dir and make tmpfs for tmp dir'
	@mkdir $(AUTOLAB)/log
	@mkdir $(AUTOLAB)/tmp
	@mount -t tmpfs /dev/shm $(AUTOLAB)/tmp
	@echo  'Make softlink to /raid/share/images, which should be nfs'
	@ln -sf /raid/share/images $(AUTOLAB)/images
	@echo  'For old version kernel, you must insert kvm modules by yourself'
	@echo  '    To check:   lsmod | grep kvm'
	@echo  '    To insmod:  modprobe kvm kvm_intel'

dist_clean: tashi_stop
	@echo  'Remove all link dirs'
	@unlink $(AUTOLAB)/bin
	@unlink $(AUTOLAB)/images
	@echo  'Remove all repos'
	@rm -fr $(AUTOLAB)/build
	@echo  'Remove all log files'
	@rm -fr $(AUTOLAB)/log
	@echo  'Unmount and remove tmp dir'
	@umount $(AUTOLAB)/tmp
	@rm -fr $(AUTOLAB)/tmp

dist_update:
	@git reset --hard HEAD
	@git remote update origin
	@git merge origin/master

install_rpyc:
	@echo  'Cloning rpyc (repo $(AUTOLAB)/build/rpyc) ...'
	@git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/build/rpyc
	@echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/build/rpyc; python setup.py install	> $(BUILDLOG)

install_tashi:
	@echo  'Cloning tashi (repo $(AUTOLAB)/build/tashi) ...'
	@git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/build/tashi
	@echo  'Reset git repo to our prefer commit'
	@cd $(AUTOLAB)/build/tashi; git reset --hard --quiet 87f55e4d30800c085ea786bf40c9412b816969e6
	@echo  'Installing tashi ...'
	@cd $(AUTOLAB)/build/tashi; make
	@echo  'Link tashi binary dir to bin dir ...'
	@ln -sf $(AUTOLAB)/build/tashi/bin $(AUTOLAB)/bin

install_qemu:
	@echo  'Cloning qemu (repo $(AUTOLAB)/build/qemu) ...'
	@git clone --quiet git://git.qemu.org/qemu.git $(AUTOLAB)/build/qemu
	@echo  'Configuring qemu (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/build/qemu; ./configure --with-system-pixman	\
		--extra-cflags="-I/usr/local/include/pixman-1"		\
		--extra-ldflags="-lpixman-1"			> $(BUILDLOG)
	@echo  'Building qemu (logfile $(BUILDLOG), ten or more minutes) ...'
	@cd $(AUTOLAB)/build/qemu; make				>> $(BUILDLOG)
	@echo  'Installing qemu (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/build/qemu; make install			>> $(BUILDLOG)
