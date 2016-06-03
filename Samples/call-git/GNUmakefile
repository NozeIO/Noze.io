# GNUmakefile

PACKAGE_DIR=../..
PACKAGE=$(notdir $(shell pwd))
$(PACKAGE)_TYPE = tool

$(PACKAGE)_SWIFT_MODULES = xsys core events streams fs child_process process

$(PACKAGE)_SWIFT_FILES = main.swift

include $(PACKAGE_DIR)/xcconfig/config.make
include $(PACKAGE_DIR)/xcconfig/rules.make
