# GNUmakefile containing rules to build a Swift library or tool using either
# Swift Package Manager, or using regular makefiles.
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# include config.make if that hasn't happened yet

ifneq ($(NOZE_DID_INCLUDE_CONFIG_MAKE),yes)
include $(SELF_DIR)config.make
endif


# setup defaults

ifeq ($(PACKAGE_DIR),)
PACKAGE_DIR=.
endif

ifeq ($(PACKAGE),)
PACKAGE=$(notdir $(shell pwd))
endif

# automagically lookup Swift files
ifeq ($($(PACKAGE)_SWIFT_FILES),)
$(PACKAGE)_SWIFT_FILES = \
  $(filter-out Package.swift,$(wildcard *.swift) $(wildcard */*.swift))
endif

# check whether main.swift is available, and set TYPE to `tool` or `library`
ifeq ($($(PACKAGE)_TYPE),)
ifneq (,$(findstring main.swift,$($(PACKAGE)_SWIFT_FILES)))
$(PACKAGE)_TYPE = tool
else
$(PACKAGE)_TYPE = library
endif
endif


#include actual rules file, depending on the available build tool

ifeq ($(HAVE_SPM),yes)

include $(SELF_DIR)rules-spm.make

else # got no Swift Package Manager, or disabled

include $(SELF_DIR)rules-makefile.make

endif
