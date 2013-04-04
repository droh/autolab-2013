AUTOLAB = /opt/autolab-2013
Q = @-

BUILDLOG = $(AUTOLAB)/build/buildlog-$@

# Config file for tashi
CFG_CM = $(AUTOLAB)/build/tashi/etc/TashiDefaults.cfg
CFG_NM = $(AUTOLAB)/build/tashi/etc/NodeManager.cfg

# Cluster manager host
HOST_CM = reefshark.ics.cs.cmu.edu

# Key for DhcpDns
KEY_NAME = reefshark
KEY_OLD = ABcdEf12GhIJKLmnOpQrsT==
KEY_NEW = IiMIY9C0IawK8TZAca7bCQ==

# Names for bridge and interface
NAME_BR = br2013
NAME_IF = em2

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
	@echo  '    node_qemuinit		- Initialize qemu environment for node'
	@echo  'Tashi operations:'
	@echo  '    tashi_status		- Show tashi status with getHosts and getInstances'
	@echo  '    tashi_stop			- Kill all tashi processes and tmp files'

node_netinit:
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

noet_qemuinit:
	@echo  'Softlink qemu-system-x86_64 in case of existence'
	@ln -sf /usr/local/bin/qemu-system-x86_64 $(AUTOLAB)/bin/

tashi_status:
	@$(AUTOLAB)/bin/tashi-client getHosts
	@$(AUTOLAB)/bin/tashi-client getInstances

tashi_test:
	@$(AUTOLAB)/bin/tashi-client createVm --name gxt --disks rhel.img
	@$(AUTOLAB)/bin/primitive &

tashi_stop:
	$(Q)echo  'Cleaning files in tmp dir, which will affect the next running of tashi'
	$(Q)rm -fr $(AUTOLAB)/tmp/*
	$(Q)echo  'Killing all possibly running processes ...'
	$(Q)killall -9 clustermanager nodemanager primitive qemu-system-x86_64

dist_init:
	@echo  'Create bin, log and tmp dir and make tmpfs for tmp dir'
	@mkdir $(AUTOLAB)/bin
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
	@unlink $(AUTOLAB)/images
	@echo  'Remove all repos'
	@rm -fr $(AUTOLAB)/build
	@echo  'Remove all log files'
	@rm -fr $(AUTOLAB)/log
	@echo  'Remove binary dir'
	@rm -fr $(AUTOLAB)/bin
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
	@echo  'Patching tashi ...'
	@cd $(AUTOLAB)/build/tashi; git am $(AUTOLAB)/tashi-patches/*
	@echo  'Change AUTOLAB2013 to $(AUTOLAB)'
	@cd $(AUTOLAB)/build/tashi; git grep -l AUTOLAB2013 | xargs sed -i "s:AUTOLAB2013:$(AUTOLAB):"
	@echo  'Change localhost to $(HOST_CM)'
	@sed -i "/^host =/ s: localhost: $(HOST_CM):"				$(CFG_CM)
	@sed -i "/^clusterManagerHost =/ s: localhost: $(HOST_CM):"		$(CFG_CM)
	@sed -i "/^clusterManagerHost =/ s: localhost: $(HOST_CM):"		$(CFG_NM)
	@echo  'Update secret key'
	@sed -i "/^dnsKeyName =/ s:name_of_dns_key_hostname:$(KEY_NAME):"	$(CFG_CM)
	@sed -i "/^dhcpKeyName =/ s:OMAPI:$(KEY_NAME):"				$(CFG_CM)
	@sed -i "/^dnsSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"			$(CFG_CM)
	@sed -i "/^dhcpSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"			$(CFG_CM)
	@echo  'Server and Domain configs'
	@sed -i "/^dnsServer =/ s:1.2.3.4 53:192.168.2.1 53:"			$(CFG_CM)
	@sed -i "/^dnsDomain =/ s:tashi.example.com:vmNet2013:"			$(CFG_CM)
	@sed -i "/^dhcpServer =/ s:1.2.3.4:192.168.2.1:"			$(CFG_CM)
	@echo  'Change ipRange'
	@sed -i "/^ipRange1 =/ s:1 = 172.16.128.2-172.16.255.254:0 = 192.168.2.128-192.168.2.254:" $(CFG_CM)
	@echo  'Disable reverseDns'
	@sed -i "/^reverseDns =/ s:True:False:"					$(CFG_CM)
	@echo  'Enable hook on DhcpDns'
	@sed -i "/^#hook1 =/ s:#hook1:hook1:"					$(CFG_CM)
	@echo  'Installing tashi ...'
	@cd $(AUTOLAB)/build/tashi; make
	@echo  'Link all tashi binary files to bin dir ...'
	@for i in $(AUTOLAB)/build/tashi/bin/*; do ln -s $$i $(AUTOLAB)/bin/; done

install_qemu:
	@echo  'Cloning qemu (repo $(AUTOLAB)/build/qemu) ...'
	@git clone --quiet git://git.qemu.org/qemu.git $(AUTOLAB)/build/qemu
	@echo  'Configuring qemu (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/build/qemu; ./configure --target-list=x86_64-softmmu	> $(BUILDLOG)
	@echo  'Building qemu (logfile $(BUILDLOG), several minutes) ...'
	@cd $(AUTOLAB)/build/qemu; make -j4			>> $(BUILDLOG)
	@echo  'Installing qemu (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/build/qemu; make install			>> $(BUILDLOG)
#	@echo  'Manually copy efi-virtio.rom to /usr/local/share/qemu/ ...'
#	@cp $(AUTOLAB)/build/qemu/pc-bios/efi-virtio.rom /usr/local/share/qemu/
