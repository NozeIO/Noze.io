# GNUmakefile

PACKAGE_DIR=../..
PACKAGE=$(notdir $(shell pwd))
$(PACKAGE)_TYPE = tool

$(PACKAGE)_SWIFT_MODULES = xsys core events streams net fs dns leftpad

$(PACKAGE)_SWIFT_FILES = \
	main.swift		\
	Session.swift		\
	Channel.swift		\
	Message.swift		\
	MessageParser.swift	\
	Helpers2.swift		\
	Helpers3.swift

include $(PACKAGE_DIR)/xcconfig/config.make
include $(PACKAGE_DIR)/xcconfig/rules.make
