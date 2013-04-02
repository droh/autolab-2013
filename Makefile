AUTOLAB = /opt/autolab-2013

all:
	@echo  'Dependencies installation:'
	@echo  '  rpyc		  - Install RPyC'

rpyc:
	git clone https://github.com/tomerfiliba/rpyc $(AUTOLAB)/rpyc
	cd $(AUTOLAB)/rpyc; python setup.py install
