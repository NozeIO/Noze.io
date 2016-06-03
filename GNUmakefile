# GNUmakefile

PACKAGE_DIR=.
debug=on

include $(PACKAGE_DIR)/xcconfig/config.make


MODULES = \
	http_parser 	\
	freddy  	\
	base64		\
	mustache	\
	xsys		\
	core		\
	leftpad		\
	events		\
	streams		\
	json		\
	fs		\
	dns		\
	net		\
	console 	\
	http		\
	process 	\
	child_process	\
	connect 	\
	express

ifeq ($(HAVE_SPM),yes)

all :
	$(SWIFT_BUILD_TOOL)

clean :
	$(SWIFT_CLEAN_TOOL)
	@$(MAKE) -C Samples clean

distclean : clean
	rm -rf .build
	@$(MAKE) -C Samples distclean

tests : all
	$(SWIFT_TEST_TOOL)

samples ::
	@$(MAKE) -C Samples all

else

MODULE_LIBS = \
  $(addsuffix $(SHARED_LIBRARY_SUFFIX),$(addprefix $(SHARED_LIBRARY_PREFIX),$(MODULES)))
MODULE_BUILD_RESULTS = $(addprefix $(SWIFT_BUILD_DIR)/,$(MODULE_LIBS))

all :
	@$(MAKE) -C Sources/http_parser      all
	@$(MAKE) -C Sources/Freddy           all
	@$(MAKE) -C Sources/base64           all
	@$(MAKE) -C Sources/mustache         all
	@$(MAKE) -C Sources/xsys             all
	@$(MAKE) -C Sources/core             all
	@$(MAKE) -C Sources/leftpad          all
	@$(MAKE) -C Sources/events           all
	@$(MAKE) -C Sources/streams          all
	@$(MAKE) -C Sources/json             all
	@$(MAKE) -C Sources/fs               all
	@$(MAKE) -C Sources/dns              all
	@$(MAKE) -C Sources/net              all
	@$(MAKE) -C Sources/process          all
	@$(MAKE) -C Sources/console          all
	@$(MAKE) -C Sources/http             all
	@$(MAKE) -C Sources/child_process    all
	@$(MAKE) -C Sources/connect          all
	@$(MAKE) -C Sources/express          all

samples :
	@$(MAKE) -C Samples all

clean :
	rm -rf .build
	@$(MAKE) -C Samples clean

distclean : clean

# TODO: make this work:
# all : $(MODULE_BUILD_RESULTS)
#$(SWIFT_BUILD_DIR)/$(SHARED_LIBRARY_PREFIX)%$(SHARED_LIBRARY_SUFFIX) ::
#	@$(MAKE) -C Sources/$@ all

endif

apidox :
	jazzy --module xsys          --output apidox/xsys
	jazzy --module core          --output apidox/core
	jazzy --module leftpad       --output apidox/leftpad
	jazzy --module events        --output apidox/events
	jazzy --module streams       --output apidox/streams
	jazzy --module json          --output apidox/json
	jazzy --module fs            --output apidox/fs
	jazzy --module dns           --output apidox/dns
	jazzy --module net           --output apidox/net
	jazzy --module http          --output apidox/http
	jazzy --module process       --output apidox/process
	jazzy --module console       --output apidox/console
	jazzy --module child_process --output apidox/child_process all
	jazzy --module connect       --output apidox/connect
	jazzy --module express       --output apidox/express
