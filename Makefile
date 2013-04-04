AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/build/buildlog-$@

all:
	@echo  'Distribution init and clean:'
	@echo  '    dist_init			- Create necessary dirs and insert kernel modules'
	@echo  '    dist_clean			- Remove all repos and log files'
	@echo  'Dependencies installation:'
	@echo  '    install_rpyc		- Install RPyC'
	@echo  '    install_tashi		- Install tashi'
	@echo  '    install_qemu		- Install QEMU'
	@echo  'Tashi operations:'
	@echo  '    tashi_status		- Show tashi status with getHosts and getInstances'
	@echo  '    tashi_stop			- Kill all tashi processes and tmp files'

tashi_status:
	@$(AUTOLAB)/bin/tashi_client getHosts
	@$(AUTOLAB)/bin/tashi_client getInstances

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
	@ln -sf /raid/share/images/ $(AUTOLAB)/images
	@echo  'Insert kernel modules for kvm'
	@modprobe kvm
	@modprobe kvm_intel

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
	@git clone --quiet git://git.qemu.org/qemu.git
	@cd $(AUTOLAB)/build/qemu; ./configure --with-system-pixman	\
		--extra-cflags="-I/usr/local/include/pixman-1"		\
		--extra-ldflags="-lpixman-1"; make; make install	> $(BUILDLOG)
