AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/log/buildlog-$@

all:
	@echo  'Preparations:'
	@echo  '  prepare	  - Create necessary dirs and insert kernel modules'
	@echo  'Dependencies installation:'
	@echo  '  rpyc		  - Install RPyC'
	@echo  '  tashi		  - Install tashi'
	@echo  '  qemu		  - Install QEMU'
	@echo  'Tashi operations:'
	@echo  '  tashi_stop	  - Kill all tashi processes and tmp files'
	@echo  'Cleaning targets:'
	@echo  '  distclean	  - Remove all repos and log files'

prepare:
	@echo  'Create log and tmp dir and make tmpfs for tmp dir'
	@mkdir $(AUTOLAB)/log
	@mkdir $(AUTOLAB)/tmp
	@mount -t tmpfs /dev/shm $(AUTOLAB)/tmp
	@echo  'Make softlink to /raid/share/images, which should be nfs'
	@ln -sf /raid/share/images/ $(AUTOLAB)/images
	@echo  'Insert kernel modules for kvm'
	@modprobe kvm
	@modprobe kvm_intel

tashi_stop:
	@echo  'Killing all possibly running processes ...'
	@killall -9 clustermanager nodemanager primitive qemu-system-x86_64
	@echo  'Cleaning files in tmp dir, which will affect the next running of tashi'
	@rm -fr $(AUTOLAB)/tmp/*

distclean: tashi_stop
	@echo  'Remove all repos and log files'
	@rm -fr $(AUTOLAB)/tashi
	@rm -fr $(AUTOLAB)/rpyc
	@rm -fr $(AUTOLAB)/log/*

rpyc:
	@echo  'Cloning rpyc (repo $(AUTOLAB)/rpyc) ...'
	@git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/rpyc

	@echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/rpyc; python setup.py install	> $(BUILDLOG)

tashi:
	@echo  'Cloning tashi (repo $(AUTOLAB)/tashi) ...'
	@git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/tashi

	@echo  'Reset git repo to our prefer commit'
	@cd $(AUTOLAB)/tashi; git reset --hard --quiet 87f55e4d30800c085ea786bf40c9412b816969e6

	@echo  'Installing tashi ...'
	@cd $(AUTOLAB)/tashi; make

qemu:
	@echo  'Cloning qemu (repo $(AUTOLAB)/qemu) ...'
	@git clone --quiet git://git.qemu.org/qemu.git
	@cd $(AUTOLAB)/qemu; ./configure --with-system-pixman		\
		--extra-cflags="-I/usr/local/include/pixman-1"		\
		--extra-ldflags="-lpixman-1"; make; make install	> $(BUILDLOG)
