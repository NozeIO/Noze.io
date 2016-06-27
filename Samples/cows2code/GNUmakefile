# GNUmakefile

NOZE_DIR=../..
PACKAGE=$(notdir $(shell pwd))

$(PACKAGE)_SWIFT_MODULES = xsys core events streams fs console

include $(NOZE_DIR)/xcconfig/rules.make

run : $(SWIFT_BUILD_DIR)/$(PACKAGE)
	$< $(NOZE_DIR)/Sources/cows/cows.txt

