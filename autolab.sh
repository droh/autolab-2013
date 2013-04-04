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

	# 1.3: Change localhost to reefshark.ics.cs.cmu.edu
	sed -i "/^host =/ s: localhost: $HOST_CM:"				$CFG_CM
	sed -i "/^clusterManagerHost =/ s: localhost: $HOST_CM:"		$CFG_CM
	sed -i "/^clusterManagerHost =/ s: localhost: $HOST_CM:"		$CFG_NM

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
