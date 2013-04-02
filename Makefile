AUTOLAB = /opt/autolab-2013

BUILDLOG = $(AUTOLAB)/log/buildlog-$@

all:
	@echo  'Dependencies installation:'
	@echo  '  rpyc		  - Install RPyC'
	@echo  '  tashi		  - Install tashi'
	@echo  'Cleaning targets:'
	@echo  '  distclean	  - Remove all repos and log files'

tashi_stop:
	@echo  'Killing all possibly running processes ...'
	@killall -9 clustermanager
	@killall -9 nodemanager
	@killall -9 primitive
	@killall -9 qemu-system-x86_64
	@echo  'Cleaning files in tmp dir, which will affect the next running of tashi'
	@rm -fr $(AUTOLAB)/tmp/*

distclean: tashi_stop
	@echo  'Remove all repos and log files'
	@rm -fr $(AUTOLAB)/tashi
	@rm -fr $(AUTOLAB)/rpyc
	@rm -fr $(AUTOLAB)/log/*

rpyc:
	@echo  'Cloning rpyc (repo $(AUTOLAB)/rpyc) ...'
	@git clone --quiet https://github.com/tomerfiliba/rpyc $(AUTOLAB)/rpyc

	@echo  'Installing rpyc (logfile $(BUILDLOG)) ...'
	@cd $(AUTOLAB)/rpyc; python setup.py install	> $(BUILDLOG)

tashi:
	@echo  'Cloning tashi (repo $(AUTOLAB)/tashi) ...'
	@git clone --quiet https://github.com/apache/tashi $(AUTOLAB)/tashi

	@echo  'Reset git repo to our prefer commit'
	@cd $(AUTOLAB)/tashi; git reset --hard --quiet 87f55e4d30800c085ea786bf40c9412b816969e6

	@echo  'Installing tashi ...'
	@cd $(AUTOLAB)/tashi; make
