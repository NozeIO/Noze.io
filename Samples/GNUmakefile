# GNUmakefile

PACKAGE_DIR=..

include $(PACKAGE_DIR)/xcconfig/config.make

SAMPLES = \
	call-git	\
	sleep		\
	echod		\
	echozd		\
	miniirc		\
	httpd-helloworld\
	httpd-static	\
	connect-static	\
	connect-git	\
	express-simple	\
	todo-mvc	\
	todo-mvc-redis

ifeq ($(HAVE_SPM),yes)

all :
	./build-all.sh

else # no SPM

all :
	@$(MAKE) -C call-git	     all
	@$(MAKE) -C sleep	     all
	@$(MAKE) -C echod	     all
	@$(MAKE) -C echozd	     all
	@$(MAKE) -C miniirc	     all
	@$(MAKE) -C httpd-helloworld all
	@$(MAKE) -C httpd-static     all
	@$(MAKE) -C connect-static   all
	@$(MAKE) -C connect-git      all
	@$(MAKE) -C express-simple   all
	@$(MAKE) -C todo-mvc         all
	@$(MAKE) -C todo-mvc-redis   all

% :
	@make -C $(PACKAGE_DIR) $@

endif # no SPM

clean :
	rm -rf */.build

distclean : clean
	rm -rf */Packages */Package.pins */Package.resolved

