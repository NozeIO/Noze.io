# GNUmakefile

PACKAGE_DIR=../..
PACKAGE=$(notdir $(shell pwd))
$(PACKAGE)_TYPE = library

$(PACKAGE)_SWIFT_MODULES = \
  xsys core events streams fs \
  process net http \
  Freddy json

include $(PACKAGE_DIR)/xcconfig/config.make
include $(PACKAGE_DIR)/xcconfig/rules.make
