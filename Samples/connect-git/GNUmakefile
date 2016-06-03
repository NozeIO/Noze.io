# GNUmakefile

NOZE_DIR=../..
PACKAGE_DIR=.
PACKAGE=$(notdir $(shell pwd))
$(PACKAGE)_TYPE = tool

$(PACKAGE)_SWIFT_MODULES = \
  xsys core events dns streams fs console net process \
  child_process \
  http base64 http_parser \
  connect Freddy json leftpad

$(PACKAGE)_SWIFT_FILES = \
	main.swift	\
	GitLogMiddleware.swift \
	Swift3.swift

include $(NOZE_DIR)/xcconfig/config.make
include $(NOZE_DIR)/xcconfig/rules.make

