AUTOLAB = /opt/autolab-2013
Q = @-

BUILDLOG = $(AUTOLAB)/build/buildlog-$@

# Config file for tashi
CFG_CM = $(AUTOLAB)/build/tashi/etc/TashiDefaults.cfg
CFG_NM = $(AUTOLAB)/build/tashi/etc/NodeManager.cfg

# Config file for qemu
ETC_QEMU_IFUP = $(AUTOLAB)/etc/qemu-ifup.0
TASHI_QEMU_PY = $(AUTOLAB)/build/tashi/src/tashi/nodemanager/vmcontrol/qemu.py

# Cluster manager host
CM_HOST = sawshark.ics.cs.cmu.edu
CM_IPADDR = 192.168.2.31

# Key for DhcpDns
KEY_NAME = sawshark
KEY_OLD = ABcdEf12GhIJKLmnOpQrsT==
KEY_NEW = od3P8BXoiLGJXL+n+raCSg==

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
	@echo  'ClusterManager operations:'
	@echo  '    cm_netstatus		- Show net status'
	@echo  '    cm_dnsinit			- Initialize dns config'
	@echo  'Node operations:'
	@echo  '    node_netinit		- Initialize net config for node'
	@echo  '    node_qemuinit		- Initialize qemu environment for node'
	@echo  'Tashi operations:'
	@echo  '    tashi_status		- Show tashi status with getHosts and getInstances'
	@echo  '    tashi_stop			- Kill all tashi processes and tmp files'
	@echo  '    tashi_test			- Create a vm and schedule it'

cm_dnsinit:
	$(Q)cp $(AUTOLAB)/etc/vmNet2013.db /var/named/
	$(Q)cp $(AUTOLAB)/etc/db.192.168.2 /var/named/
	$(Q)chown -R named:named /var/named/vmNet2013.db
	$(Q)chown -R named:named /var/named/db.192.168.2

cm_netstatus:
	$(Q)service named status
	$(Q)service dhcpd status

node_netinit:
	$(Q)echo  'Add and configure bridge'
	$(Q)brctl addbr $(NAME_BR)
	$(Q)brctl setfd $(NAME_BR) 1
	$(Q)brctl sethello $(NAME_BR) 1
	$(Q)ifdown $(NAME_IF)
	$(Q)ifconfig $(NAME_IF) 0.0.0.0
	$(Q)brctl addif $(NAME_BR) $(NAME_IF)
	$(Q)echo  'You must specify IP addr to this host by:'
	$(Q)echo  '    ifconfig $(NAME_BR) 192.168.2.xx up'

node_qemuinit:
	$(Q)echo  'Softlink qemu-system-x86_64 in case of existence'
	$(Q)ln -sf /usr/local/bin/qemu-system-x86_64 $(AUTOLAB)/bin/
	$(Q)echo  'Create $(ETC_QEMU_IFUP)'
	$(Q)echo  '#!/bin/sh'					>  $(ETC_QEMU_IFUP)
	$(Q)echo  ''						>> $(ETC_QEMU_IFUP)
	$(Q)echo  '/sbin/ifconfig $$1 0.0.0.0 up'		>> $(ETC_QEMU_IFUP)
	$(Q)echo  '/usr/sbin/brctl addif $(NAME_BR) $$1'	>> $(ETC_QEMU_IFUP)
	$(Q)echo  'exit 0'					>> $(ETC_QEMU_IFUP)
	$(Q)chmod +x $(ETC_QEMU_IFUP)

tashi_status:
	$(Q)$(AUTOLAB)/bin/tashi-client getHosts
	$(Q)$(AUTOLAB)/bin/tashi-client getInstances

tashi_test:
	$(Q)$(AUTOLAB)/bin/tashi-client createVm --name gxt --disks rhel.img
	$(Q)$(AUTOLAB)/bin/primitive &

tashi_stop:
	$(Q)echo  'Cleaning files in tmp dir, which will affect the next running of tashi'
	$(Q)rm -fr $(AUTOLAB)/tmp/*
	$(Q)echo  'Killing all possibly running processes ...'
	$(Q)killall -9 clustermanager nodemanager primitive qemu-system-x86_64

dist_init:
	$(Q)echo  'Create bin, log and tmp dir and make tmpfs for tmp dir'
	$(Q)mkdir $(AUTOLAB)/bin
	$(Q)mkdir $(AUTOLAB)/log
	$(Q)mkdir $(AUTOLAB)/tmp
	$(Q)mount -t tmpfs /dev/shm $(AUTOLAB)/tmp
	$(Q)echo  'Make softlink to /raid/share/images, which should be nfs'
	$(Q)ln -sf /raid/share/images $(AUTOLAB)/images
	$(Q)echo  'For old version kernel, you must insert kvm modules by yourself'
	$(Q)echo  '    To check:   lsmod | grep kvm'
	$(Q)echo  '    To insmod:  modprobe kvm kvm_intel'

dist_clean: tashi_stop
	$(Q)echo  'Remove all link dirs'
	$(Q)unlink $(AUTOLAB)/images
	$(Q)echo  'Remove all repos'
	$(Q)rm -fr $(AUTOLAB)/build
	$(Q)echo  'Remove all log files'
	$(Q)rm -fr $(AUTOLAB)/log
	$(Q)echo  'Remove binary dir'
	$(Q)rm -fr $(AUTOLAB)/bin
	$(Q)echo  'Unmount and remove tmp dir'
	$(Q)umount $(AUTOLAB)/tmp
	$(Q)rm -fr $(AUTOLAB)/tmp

dist_update:
	$(Q)git reset --hard HEAD
	$(Q)git remote update origin
	$(Q)git merge origin/master

install_rpyc:
	$(Q)echo  'Removing old rpyc (repo $(AUTOLAB)/build/rpyc) ...'
	$(Q)rm -fr $(AUTOLAB)/build/rpyc
	$(Q)echo  'Cloning rpyc (repo $(AUTOLAB)/build/rpyc) ...'
	$(Q)git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/build/rpyc
	$(Q)echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	$(Q)cd $(AUTOLAB)/build/rpyc; /usr/local/bin/python setup.py install	> $(BUILDLOG)

install_tashi:
	$(Q)echo  'Removing old tashi (repo $(AUTOLAB)/build/tashi) ...'
	$(Q)rm -fr $(AUTOLAB)/build/tashi
	$(Q)echo  'Cloning tashi (repo $(AUTOLAB)/build/tashi) ...'
	$(Q)git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/build/tashi
	$(Q)echo  'Reset git repo to our prefer commit'
	$(Q)cd $(AUTOLAB)/build/tashi; git reset --hard --quiet 87f55e4d30800c085ea786bf40c9412b816969e6
	$(Q)echo  'Patching tashi ...'
	$(Q)cd $(AUTOLAB)/build/tashi; git am $(AUTOLAB)/tashi-patches/*
	$(Q)echo  'Change AUTOLAB2013 to $(AUTOLAB)'
	$(Q)cd $(AUTOLAB)/build/tashi; git grep -l AUTOLAB2013 | xargs sed -i "s:AUTOLAB2013:$(AUTOLAB):"
	$(Q)echo  'Change localhost to $(CM_HOST)'
	$(Q)sed -i "/^host =/ s: localhost: $(CM_HOST):"			$(CFG_CM)
	$(Q)sed -i "/^clusterManagerHost =/ s: localhost: $(CM_HOST):"		$(CFG_CM)
	$(Q)sed -i "/^clusterManagerHost =/ s: localhost: $(CM_HOST):"		$(CFG_NM)
	$(Q)sed -i "/^clustermanagerhost =/ s: localhost: $(CM_HOST):"		$(CFG_NM)
	$(Q)echo  'Update secret key'
	$(Q)sed -i "/^dnsKeyName =/ s:name_of_dns_key_hostname:$(KEY_NAME):"	$(CFG_CM)
	$(Q)sed -i "/^dhcpKeyName =/ s:OMAPI:$(KEY_NAME):"			$(CFG_CM)
	$(Q)sed -i "/^dnsSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"			$(CFG_CM)
	$(Q)sed -i "/^dhcpSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"		$(CFG_CM)
	$(Q)echo  'Server and Domain configs'
	$(Q)sed -i "/^dnsServer =/ s:1.2.3.4 53:$(CM_IPADDR) 53:"		$(CFG_CM)
	$(Q)sed -i "/^dnsDomain =/ s:tashi.example.com:vmNet2013:"		$(CFG_CM)
	$(Q)sed -i "/^dhcpServer =/ s:1.2.3.4:$(CM_IPADDR):"			$(CFG_CM)
	$(Q)echo  'Change ipRange'
	$(Q)sed -i "/^ipRange1 =/ s:1 = 172.16.128.2-172.16.255.254:0 = 192.168.2.128-192.168.2.254:" $(CFG_CM)
	$(Q)echo  'Disable reverseDns'
	$(Q)sed -i "/^reverseDns =/ s:True:False:"				$(CFG_CM)
	$(Q)echo  'Enable hook on DhcpDns'
	$(Q)sed -i "/^#hook1 =/ s:#hook1:hook1:"				$(CFG_CM)
	$(Q)echo  'FIXME: Remove "-balloon virtio" in qemu.py in tashi'
	$(Q)sed -i "/strCmd =/ s:-balloon virtio::"				$(TASHI_QEMU_PY)
	$(Q)echo  'Do git add to make life easier ...'
	$(Q)cd $(AUTOLAB)/build/tashi; git add .
	$(Q)echo  'Installing tashi ...'
	$(Q)cd $(AUTOLAB)/build/tashi; make
	$(Q)echo  'Link all tashi binary files to bin dir ...'
	$(Q)for i in $(AUTOLAB)/build/tashi/bin/*; do ln -s $$i $(AUTOLAB)/bin/; done

install_qemu:
	$(Q)echo  'Cloning qemu (repo $(AUTOLAB)/build/qemu) ...'
	$(Q)git clone --quiet git://git.qemu.org/qemu.git $(AUTOLAB)/build/qemu
	$(Q)echo  'Configuring qemu (logfile $(BUILDLOG)) ...'
	$(Q)cd $(AUTOLAB)/build/qemu; ./configure --target-list=x86_64-softmmu	> $(BUILDLOG)
	$(Q)echo  'Building qemu (logfile $(BUILDLOG), several minutes) ...'
	$(Q)cd $(AUTOLAB)/build/qemu; make -j4			>> $(BUILDLOG)
	$(Q)echo  'Installing qemu (logfile $(BUILDLOG)) ...'
	$(Q)cd $(AUTOLAB)/build/qemu; make install			>> $(BUILDLOG)
#	$(Q)echo  'Manually copy efi-virtio.rom to /usr/local/share/qemu/ ...'
#	$(Q)cp $(AUTOLAB)/build/qemu/pc-bios/efi-virtio.rom /usr/local/share/qemu/
