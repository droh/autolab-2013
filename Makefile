AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/log/buildlog-$@

all:
	@echo  'Dependencies installation:'
	@echo  '  rpyc		  - Install RPyC'

rpyc:
	@echo  'Cloning rpyc (repo $(AUTOLAB)/rpyc) ...'
	@git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/rpyc

	@echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/rpyc; python setup.py install	> $(BUILDLOG)
