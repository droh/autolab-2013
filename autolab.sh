#!/bin/bash

# Add autolab-2013 alias
export AUTOLAB=/opt/autolab-2013
# Add tashi/src to PYTHONPATH
export PYTHONPATH=$AUTOLAB/build/tashi/src
if [ -d /usr/share/tashi ]; then
	echo 'The /usr/share/tashi must be renamed or removed, to avoid conflict configuration.'
	mv /usr/share/tashi /usr/share/tashi.backup
fi

tashi_init()
{
	# Filenames
	CFG_CM=$AUTOLAB/build/tashi/etc/TashiDefaults.cfg
	CFG_NM=$AUTOLAB/build/tashi/etc/NodeManager.cfg
	CFG_AG=$AUTOLAB/build/tashi/etc/Agent.cfg
	CFG_AC=$AUTOLAB/build/tashi/etc/Accounting.cfg
	PYQEMU=$AUTOLAB/build/tashi/src/tashi/nodemanager/vmcontrol/qemu.py
	PYUTIL=$AUTOLAB/build/tashi/src/tashi/util.py
	PY_NMD=$AUTOLAB/build/tashi/src/utils/nmd.py

	# Configuration values
	HOST_CM=reefshark.ics.cs.cmu.edu

	cd $AUTOLAB/build/tashi; git reset --hard HEAD

	# 0: BUGFIX for the tashi
	# 0.1: FIX authenticators problem (for RPyC 3.3.0 incompatibility)
	sed -i "s:TlsliteVdb:SSL:" $AUTOLAB/build/tashi/src/tashi/clustermanager/clustermanager.py
	sed -i "s:TlsliteVdb:SSL:" $AUTOLAB/build/tashi/src/tashi/nodemanager/nodemanager.py
	# 0.2: FIX pts device bug (new qemu/old kernel compatibility)
	sed -i "/ptyFile=line/ s:strip():partition(\" \")[0]:"			$PYQEMU

	# 1: Environment establishment
	# 1.1: Specify config dir, so we can use default config files
	sed -i "/baseLocations =/ s:/usr/local/tashi:$AUTOLAB/build/tashi:"	$PYUTIL
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

	# 3: Enable DhcpDns
	# 3.1: Update secret key
	sed -i "/^dnsKeyName =/ s:name_of_dns_key_hostname:reefshark:"		$CFG_CM
	sed -i "/^dhcpKeyName =/ s:OMAPI:reefshark:"				$CFG_CM
	sed -i "/^dnsSecretKey =/ s:ABcdEf12GhIJKLmnOpQrsT==:IiMIY9C0IawK8TZAca7bCQ==:" $CFG_CM
	sed -i "/^dhcpSecretKey =/ s:ABcdEf12GhIJKLmnOpQrsT==:IiMIY9C0IawK8TZAca7bCQ==:" $CFG_CM
	# 3.2: Server and Domain configs
	sed -i "/^dnsServer =/ s:1.2.3.4 53:192.168.2.1 53:"			$CFG_CM
	sed -i "/^dnsDomain =/ s:tashi.example.com:vmNet2013:"			$CFG_CM
	sed -i "/^dhcpServer =/ s:1.2.3.4:192.168.2.1:"				$CFG_CM
	# 3.3: Change ipRange
	sed -i "/^ipRange1 =/ s:1 = 172.16.128.2-172.16.255.254:0 = 192.168.2.128-192.168.2.254:" $CFG_CM
	# 3.4: Disable reverseDns
	sed -i "/^reverseDns =/ s:True:False:"					$CFG_CM
	# 3.5: Enable hook on DhcpDns
	sed -i "/^#hook1 =/ s:#hook1:hook1:"					$CFG_CM

	git add .; cd -
}
