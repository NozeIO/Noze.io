# GNUmakefile

PACKAGE_DIR=..

include $(PACKAGE_DIR)/xcconfig/config.make

all : copy-nozeio-testcase-master
	@make -C $(PACKAGE_DIR) tests

% :
	@make -C $(PACKAGE_DIR) $@

copy-nozeio-testcase-master :
	for i in child_processTests dnsTests dgramTests fsTests httpTests jsonTests netTests cryptoTests; do \
	  cp streamsTests/NozeIOTestCase.swift $$i; \
	done

test-clean :
	rm -rf $(SWIFT_BUILD_DIR)/*TestSuite*
