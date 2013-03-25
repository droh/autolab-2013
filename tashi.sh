#!/bin/bash

tashi_preinit()
{
	# Create subdirs and make tmpfs for tmp dir
	mkdir $AUTOLAB/etc
	mkdir $AUTOLAB/log
	mkdir $AUTOLAB/tmp
	mount -t tmpfs /dev/shm $AUTOLAB/tmp

	# Create etc/qemu-ifup.0 file
	FILE_QEMUIFUP=$AUTOLAB/etc/qemu-ifup.0
	echo '#!/bin/sh'			>  $FILE_QEMUIFUP
	echo ''					>> $FILE_QEMUIFUP
	echo '/sbin/ifconfig $1 0.0.0.0 up'	>> $FILE_QEMUIFUP
	echo '/usr/sbin/brctl addif NAME_BR $1'	>> $FILE_QEMUIFUP
	echo 'exit 0'				>> $FILE_QEMUIFUP
	chmod +x $FILE_QEMUIFUP

	# Insert linux modules for kvm
	modprobe kvm
	modprobe kvm_intel

	# Get tashi and make it
	git clone https://github.com/apache/tashi $AUTOLAB/tashi
	cd $AUTOLAB/tashi; make; cd -
}

tashi_server_netinit()
{
	# Root privilege required
	NAME_BR=br0
	NAME_IF=em2

	brctl addbr $NAME_BR
	brctl setfd $NAME_BR 1
	brctl sethello $NAME_BR 1
	ifdown $NAME_IF
	ifconfig $NAME_IF 0.0.0.0
	brctl addif $NAME_BR $NAME_IF
	ifconfig $NAME_BR 192.168.2.1 up

	# Change the name in qemu-ifup.0
	sed -i "s:NAME_BR:$NAME_BR:" $AUTOLAB/etc/qemu-ifup.0

	# /raid is nfs, and we need images from here
	ln -sf /raid/shared/images/ $AUTOLAB/images
}

tashi_client_netinit()
{
	# /raid is nfs, and we need images from here
	ln -sf /raid/share/images/ $AUTOLAB/images
}

tashi_init()
{
	# Filenames
	CFG_CM=$AUTOLAB/tashi/etc/TashiDefaults.cfg
	CFG_NM=$AUTOLAB/tashi/etc/NodeManager.cfg
	CFG_AG=$AUTOLAB/tashi/etc/Agent.cfg
	CFG_AC=$AUTOLAB/tashi/etc/Accounting.cfg
	PYQEMU=$AUTOLAB/tashi/src/tashi/nodemanager/vmcontrol/qemu.py
	PYUTIL=$AUTOLAB/tashi/src/tashi/util.py
	PY_NMD=$AUTOLAB/tashi/src/utils/nmd.py

	# Configuration values
	HOST_CM=reefshark.ics.cs.cmu.edu

	# 0: BUGFIX for the tashi
	# 0.1: FIX authenticators problem (for RPyC 3.3.0 incompatibility)
	sed -i "s:TlsliteVdb:SSL:" $AUTOLAB/tashi/src/tashi/clustermanager/clustermanager.py
	sed -i "s:TlsliteVdb:SSL:" $AUTOLAB/tashi/src/tashi/nodemanager/nodemanager.py
	# 0.2: FIX pts device bug (new qemu/old kernel compatibility)
	sed -i "/ptyFile=line/ s:strip():partition(\" \")[0]:"			$PYQEMU

	# 1: Environment establishment
	# 1.1: Specify config dir, so we can use default config files
	sed -i "/baseLocations =/ s:/usr/local/tashi:$AUTOLAB/tashi:"		$PYUTIL
	# 1.2: Solve NM init loop problem: enable registerHost by default
	sed -i "/^registerHost =/ s: False: True:"				$CFG_CM
	sed -i "/^registerHost =/ s: False: True:"				$CFG_NM
	# 1.3: Change localhost to reefshark.ics.cs.cmu.edu
	sed -i "/^host =/ s: localhost: $HOST_CM:"				$CFG_CM
	sed -i "/^clusterManagerHost =/ s: localhost: $HOST_CM:"		$CFG_CM
	sed -i "/^clusterManagerHost =/ s: localhost: $HOST_CM:"		$CFG_NM
	# 1.4: Specify images dir to $AUTOLAB/images
	sed -i "/^prefix =/ s: /tmp: $AUTOLAB:"					$CFG_CM
	sed -i "/^prefix =/ s: /tmp: $AUTOLAB:"					$CFG_NM
	# 1.5: Specify correct qemuBin
	sed -i "/^qemuBin =/ s:/usr/bin/kvm:/usr/local/bin/qemu-system-x86_64:"	$CFG_CM
	# 1.6: Enable file logger
	sed -i "/^keys =/ s:consoleHandler:&,fileHandler:"			$CFG_CM
	sed -i "/^keys =/ s:consoleHandler:&,fileHandler:"			$CFG_NM
	sed -i "/^handlers =/ s:consoleHandler:&,fileHandler:"			$CFG_CM
	sed -i "/^handlers =/ s:consoleHandler:&,fileHandler:"			$CFG_NM

	# 2: Put everything in one piece
	# 2.1: Use $AUTOLAB/tmp instead of /var/tmp or /tmp
	sed -i "/^file =/ s:/var/tmp:$AUTOLAB/tmp:"				$CFG_CM
	sed -i "/self.INFO_DIR =/ s:/var/tmp:$AUTOLAB/tmp:"			$PYQEMU
	sed -i "s:\"/tmp:\"$AUTOLAB/tmp:"					$PYQEMU
	# 2.2: Use $AUTOLAB/log instead of /var/log
	sed -i "/^args =/ s:/var/log:$AUTOLAB/log:"				$CFG_AG
	sed -i "/^args =/ s:/var/log:$AUTOLAB/log:"				$CFG_AC
	sed -i "/^args =/ s:/var/log:$AUTOLAB/log:"				$CFG_CM
	sed -i "/^LOGFILE=/ s:/var/log:$AUTOLAB/log:"				$PY_NMD
	# 2.3: Use $AUTOLAB/etc instead of /etc
	sed -i "/nicString =/ s:/etc/qemu-ifup:$AUTOLAB&:"			$PYQEMU
}

tashi_start()
{
	$AUTOLAB/tashi/bin/clustermanager &
	$AUTOLAB/tashi/bin/nodemanager &
}

tashi_test()
{
	$AUTOLAB/tashi/bin/tashi-client createVm --name gxt --disks rhel.img
	$AUTOLAB/tashi/bin/primitive
}

tashi_stop()
{
	killall -9 clustermanager
	killall -9 nodemanager
	killall -9 primitive
	killall -9 qemu-system-x86_64
	# Files in tmp dir affect the new running of tashi, so remove them
	rm -fr $AUTOLAB/tmp/*
}

tashi_clean()
{
	cd $AUTOLAB/tashi; git reset --hard HEAD; cd -
	rm -fr $AUTOLAB/log/*
}

# autolab-2013 alias
export AUTOLAB=/opt/autolab-2013

# Add tashi/src to PYTHONPATH
export PYTHONPATH=$AUTOLAB/tashi/src
