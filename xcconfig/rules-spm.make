# GNUmakefile

# this needs fixing for tests
ifneq ($($(PACKAGE)_TYPE),testsuite)
all         : $(SWIFT_BUILD_DIR)/$(PACKAGE)
all-tool    : all
all-library : all

clean :
	(cd $(PACKAGE_DIR); $(SWIFT_CLEAN_TOOL))

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_BUILD_TOOL))

run : $(SWIFT_BUILD_DIR)/$(PACKAGE)
	$<

else # testsuite

all         : $(SWIFT_BUILD_DIR)/$(PACKAGE)TestSuite.build/master.swiftdeps
all-tests   : all

$(SWIFT_BUILD_DIR)/$(PACKAGE)TestSuite.build/master.swiftdeps : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_TEST_TOOL))

tests : all

clean :
	rm -rf $(SWIFT_BUILD_DIR)/$(PACKAGE)TestSuite.build

endif
