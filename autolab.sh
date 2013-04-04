#!/bin/bash

# Add autolab-2013 alias
export AUTOLAB=/opt/autolab-2013
# Add tashi/src to PYTHONPATH
export PYTHONPATH=$AUTOLAB/tashi/src
if [ -d /usr/share/tashi ]; then
	echo 'The /usr/share/tashi must be renamed or removed, to avoid conflict configuration.'
	mv /usr/share/tashi /usr/share/tashi.backup
fi
