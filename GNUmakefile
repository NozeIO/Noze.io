# GNUmakefile

PACKAGE_DIR=.
debug=on

include $(PACKAGE_DIR)/xcconfig/config.make


MODULES = \
	http_parser 	\
	Freddy  	\
	CryptoSwift 	\
	base64		\
	mustache	\
	xsys		\
	core		\
	leftpad		\
	events		\
	streams		\
	crypto		\
	fs		\
	json		\
	dns		\
	net		\
	console 	\
	http		\
	process 	\
	child_process	\
	connect 	\
	express		\
        redis           \
	cows

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
	@$(MAKE) -C Sources/CryptoSwift      all
	@$(MAKE) -C Sources/base64           all
	@$(MAKE) -C Sources/mustache         all
	@$(MAKE) -C Sources/xsys             all
	@$(MAKE) -C Sources/core             all
	@$(MAKE) -C Sources/leftpad          all
	@$(MAKE) -C Sources/events           all
	@$(MAKE) -C Sources/streams          all
	@$(MAKE) -C Sources/crypto           all
	@$(MAKE) -C Sources/fs               all
	@$(MAKE) -C Sources/json             all
	@$(MAKE) -C Sources/dns              all
	@$(MAKE) -C Sources/net              all
	@$(MAKE) -C Sources/process          all
	@$(MAKE) -C Sources/console          all
	@$(MAKE) -C Sources/http             all
	@$(MAKE) -C Sources/child_process    all
	@$(MAKE) -C Sources/connect          all
	@$(MAKE) -C Sources/express          all
	@$(MAKE) -C Sources/redis            all
	@$(MAKE) -C Sources/cows             all

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

docker-build-52:
	mkdir -p .docker52.build .docker52.Packages
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker52.build:/src/.build	\
		-v $(PWD)/.docker52.Packages:/src/Packages \
		helje5/swift-dev:5.2.0 \
		bash -c "cd /src && swift build"

docker-build-3:
	mkdir -p .docker3.build .docker3.Packages
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker3.build:/src/.build	\
		-v $(PWD)/.docker3.Packages:/src/Packages \
		swift:3.1.1 \
		bash -c "cd /src && swift build"

docker-build-4:
	mkdir -p .docker4.build
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker4.build:/src/.build	\
		swift:4.0.2 \
		bash -c "cd /src && swift build"

# Note: this segfaults in QEmu (in Docker on macOS)
docker-build-3-rpi-samples:
	mkdir -p .docker3arm.build .docker3arm.Packages
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker3arm.build:/src/.build	\
		-v $(PWD)/.docker3arm.Packages:/src/Packages \
		helje5/rpi-swift:3.1.1 \
		bash -c "cd /src && swift build && git tag --force 0.3.33 && cd Samples && make distclean && make && git tag -d 0.3.33"

docker-build-3-samples:
	mkdir -p .docker3.build .docker3.Packages
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker3.build:/src/.build	\
		-v $(PWD)/.docker3.Packages:/src/Packages \
		swift:3.1.1 \
		bash -c "cd /src && swift build && git tag --force 0.3.33 && cd Samples && make distclean && make && git tag -d 0.3.33"

docker-build-4-samples:
	mkdir -p .docker4.build
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker4.build:/src/.build	\
		swift:4.0.2 \
		bash -c "cd /src && swift build && git tag --force 0.3.33 && cd Samples && make distclean && make && git tag -d 0.3.33"

docker-clean:
	rm -rf .docker3.* .docker4.* .docker3arm.*
