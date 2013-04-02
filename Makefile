AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/log/buildlog-$@

all:
	@echo  'Dependencies installation:'
	@echo  '  rpyc		  - Install RPyC'
	@echo  '  tashi		  - Install tashi'

rpyc:
	@echo  'Cloning rpyc (repo $(AUTOLAB)/rpyc) ...'
	@git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/rpyc

	@echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/rpyc; python setup.py install	> $(BUILDLOG)

tashi:
	@echo  'Cloning tashi (repo $(AUTOLAB)/tashi) ...'
	@git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/tashi

	@echo  'Installing tashi ...'
	@cd $(AUTOLAB)/tashi; make
