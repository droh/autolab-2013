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
	$(Q)echo  'Add and configure bridge'
	$(Q)brctl addbr $(NAME_BR)
	$(Q)brctl setfd $(NAME_BR) 1
	$(Q)brctl sethello $(NAME_BR) 1
	$(Q)ifdown $(NAME_IF)
	$(Q)ifconfig $(NAME_IF) 0.0.0.0
	$(Q)brctl addif $(NAME_BR) $(NAME_IF)
	$(Q)echo  'Change the bridge name in qemu-ifup.0'
	$(Q)sed -i "s:NAME_BR:$(NAME_BR):" $(AUTOLAB)/etc/qemu-ifup.0
	$(Q)echo  'You must specify IP addr to this host by:'
	$(Q)echo  '    ifconfig $(NAME_BR) 192.168.2.xx up'

node_qemuinit:
	$(Q)echo  'Softlink qemu-system-x86_64 in case of existence'
	$(Q)ln -sf /usr/local/bin/qemu-system-x86_64 $(AUTOLAB)/bin/

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
	$(Q)echo  'Cloning rpyc (repo $(AUTOLAB)/build/rpyc) ...'
	$(Q)git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/build/rpyc
	$(Q)echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	$(Q)cd $(AUTOLAB)/build/rpyc; python setup.py install	> $(BUILDLOG)

install_tashi:
	$(Q)echo  'Cloning tashi (repo $(AUTOLAB)/build/tashi) ...'
	$(Q)git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/build/tashi
	$(Q)echo  'Reset git repo to our prefer commit'
	$(Q)cd $(AUTOLAB)/build/tashi; git reset --hard --quiet 87f55e4d30800c085ea786bf40c9412b816969e6
	$(Q)echo  'Patching tashi ...'
	$(Q)cd $(AUTOLAB)/build/tashi; git am $(AUTOLAB)/tashi-patches/*
	$(Q)echo  'Change AUTOLAB2013 to $(AUTOLAB)'
	$(Q)cd $(AUTOLAB)/build/tashi; git grep -l AUTOLAB2013 | xargs sed -i "s:AUTOLAB2013:$(AUTOLAB):"
	$(Q)echo  'Change localhost to $(HOST_CM)'
	$(Q)sed -i "/^host =/ s: localhost: $(HOST_CM):"			$(CFG_CM)
	$(Q)sed -i "/^clusterManagerHost =/ s: localhost: $(HOST_CM):"		$(CFG_CM)
	$(Q)sed -i "/^clusterManagerHost =/ s: localhost: $(HOST_CM):"		$(CFG_NM)
	$(Q)echo  'Update secret key'
	$(Q)sed -i "/^dnsKeyName =/ s:name_of_dns_key_hostname:$(KEY_NAME):"	$(CFG_CM)
	$(Q)sed -i "/^dhcpKeyName =/ s:OMAPI:$(KEY_NAME):"			$(CFG_CM)
	$(Q)sed -i "/^dnsSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"			$(CFG_CM)
	$(Q)sed -i "/^dhcpSecretKey =/ s:$(KEY_OLD):$(KEY_NEW):"		$(CFG_CM)
	$(Q)echo  'Server and Domain configs'
	$(Q)sed -i "/^dnsServer =/ s:1.2.3.4 53:192.168.2.1 53:"		$(CFG_CM)
	$(Q)sed -i "/^dnsDomain =/ s:tashi.example.com:vmNet2013:"		$(CFG_CM)
	$(Q)sed -i "/^dhcpServer =/ s:1.2.3.4:192.168.2.1:"			$(CFG_CM)
	$(Q)echo  'Change ipRange'
	$(Q)sed -i "/^ipRange1 =/ s:1 = 172.16.128.2-172.16.255.254:0 = 192.168.2.128-192.168.2.254:" $(CFG_CM)
	$(Q)echo  'Disable reverseDns'
	$(Q)sed -i "/^reverseDns =/ s:True:False:"				$(CFG_CM)
	$(Q)echo  'Enable hook on DhcpDns'
	$(Q)sed -i "/^#hook1 =/ s:#hook1:hook1:"				$(CFG_CM)
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
