# GNUmakefile

PACKAGE_DIR=../..
PACKAGE=$(notdir $(shell pwd))
$(PACKAGE)_TYPE = tool

$(PACKAGE)_SWIFT_MODULES = xsys core events streams net fs dns

$(PACKAGE)_SWIFT_FILES = main.swift

include $(PACKAGE_DIR)/xcconfig/config.make
include $(PACKAGE_DIR)/xcconfig/rules.make
