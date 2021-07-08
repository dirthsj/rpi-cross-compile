CWD = $(shell pwd)

# Cross compiler locations
PI_0_CROSS = pi-sdks/cross-gcc-10.2.0-pi_0-1
PI_3_CROSS = pi-sdks/cross-gcc-10.2.0-pi_2-3
PI_4_CROSS = pi-sdks/cross-gcc-10.2.0-pi_3+

PI_CROSS_TOOLCHAINS = $(PI_0_CROSS) \
	$(PI_3_CROSS) \
	$(PI_4_CROSS)

TOOLCHAIN_BIN = /usr/bin

ifeq ($(MAKECMDGOALS), pi0)
	TOOLCHAIN_BIN = $(abspath $(PI_0_CROSS)/bin)
endif
ifeq ($(MAKECMDGOALS), pi3)
	TOOLCHAIN_BIN = $(abspath $(PI_3_CROSS)/bin)
endif
ifeq ($(MAKECMDGOALS), pi4)
	TOOLCHAIN_BIN = $(abspath $(PI_4_CROSS)/bin)
endif

CC = $(TOOLCHAIN_BIN)/arm-linux-gnueabihf-gcc
CXX = $(TOOLCHAIN_BIN)/arm-linux-gnueabihf-g++

# If we're not cross compiling, use native gcc and g++
ifeq ($(MAKECMDGOALS), desktop)
	CC = gcc
	CXX = g++
endif

RELEASE ?= false # default to debug builds
CXXFLAGS = -Wall -Wpedantic -Wextra -std=c++17 # enable warnings, c++17, and debug symbols
LDFLAGS = -lpthread

ifeq ($(RELEASE), true)
# enable optimization for release builds
	CXXFLAGS += -O3
else
# enable debug symmbols for non-release builds
	CXXFLAGS += -g
endif

SOURCE_DIR = src
OUTPUT_DIR = out/debug/$(MAKECMDGOALS)

ifeq ($(RELEASE), true)
	OUTPUT_DIR = out/release/$(MAKECMDGOALS)
endif

OBJECT_FILES = $(addprefix $(OUTPUT_DIR)/,$(addsuffix .o, $(notdir $(basename $(wildcard $(SOURCE_DIR)/*.cpp)))))

BOOST_SOURCE = pi-sdks/boost_1_76_0
BOOST_INSTALL_PATH = $(abspath boost/$(MAKECMDGOALS))
BOOST_LINKER_PATH = $(BOOST_INSTALL_PATH)/lib
BOOST_INCLUDE_PATH = $(BOOST_INSTALL_PATH)/include
BOOST_REQUIRED_LIBRARIES = --with-test # use this to include boost libraries in compilation

TOOLCHAIN_DEP = $(addsuffix /.touch, $(dir $(TOOLCHAIN_BIN)) $(BOOST_INSTALL_PATH))

test: 
	@echo $(TOOLCHAIN_DEP)

# ifeq ($(MAKECMDGOALS), desktop)
# 	BOOST_LINKER_PATH = /usr/lib
# 	BOOST_INCLUDE_PATH = /usr/include
# endif

#
# Displays usage information about this makefile
#
.SILENT: help
.PHONY: help
help:
	printf "Usage: make <target> [arguments]\n\nTargets:\n"
	printf "\t%-15s%-10s\n" "help" "displays this message"
	printf "\t%-15s%-10s\n" "versions" "displays compiler version info"
	printf "\t%-15s%-10s\n" "desktop" "compiles for the current system"
	printf "\t%-15s%-10s\n" "pi0" "cross compiles for the pi0"
	printf "\t%-15s%-10s\n" "pi3" "cross compiles for the pi3"
	printf "\t%-15s%-10s\n" "pi4" "cross compiles for the pi4"
	printf "\t%-15s%-10s\n" "all" "compiles for desktop, pi0, pi3, and pi4 in parallel"
	printf "\t%-15s%-10s\n" "clean" "deletes built files"
	printf "\t%-15s%-10s\n" "cleantouch" "forces a rebuild of the libraries on next run"
	printf "\nArguments:\n"
	printf "\t%-15s%-10s\n" "RELEASE=true" "disables debugging symbols and enables optimization"

#
# Displays version information about the current system compiler and cross compilers
#
.PHONY: versions
versions:
	$(PI_0_CROSS)/bin/arm-linux-gnueabihf-g++ --version
	$(PI_3_CROSS)/bin/arm-linux-gnueabihf-g++ --version
	$(PI_4_CROSS)/bin/arm-linux-gnueabihf-g++ --version
	g++ --version

#
# Compiles for various platforms
#
pi0: $(TOOLCHAIN_DEP) $(OBJECT_FILES)
	$(CXX) -o pi0 $(OBJECT_FILES) $(LDFLAGS) -L$(BOOST_LINKER_PATH)

pi3: $(TOOLCHAIN_DEP) $(OBJECT_FILES) 
	$(CXX) -o pi3 $(OBJECT_FILES) $(LDFLAGS) -L$(BOOST_LINKER_PATH)

pi4: $(TOOLCHAIN_DEP) $(OBJECT_FILES)
	$(CXX) -o pi4 $(OBJECT_FILES) $(LDFLAGS) -L$(BOOST_LINKER_PATH)

desktop: $(TOOLCHAIN_DEP) $(OBJECT_FILES)
	$(CXX) -o desktop $(OBJECT_FILES) $(LDFLAGS) -L$(BOOST_LINKER_PATH)

all:
	$(MAKE) pi0 & \
	$(MAKE) pi3 & \
	$(MAKE) pi4 & \
	$(MAKE) desktop & \
	wait

#
# Removes compiled files
# does not affect boost or sdks
#
.PHONY: clean
clean:
	rm -rf out/* desktop pi0 pi3 pi4
#
# Forces rebuild of libraries by removing the touched files
#
cleantouch:
	rm -f boost/desktop/.touch \
		boost/pi0/.touch \
		boost/pi3/.touch \
		boost/pi4/.touch \

#
# Step 1 of compiling boost from source is compiling the b2 tool for your native system
# this target will extract the boost source and compile the b2 tool.
#
$(BOOST_SOURCE)/b2: $(BOOST_SOURCE).tar.gz
ifeq ("$(wildcard $(BOOST_SOURCE))", "")
	mkdir $(BOOST_SOURCE)
	tar -xvf $(BOOST_SOURCE).tar.gz --strip-components 1 -C $(BOOST_SOURCE) --exclude='doc'
endif
	cd $(BOOST_SOURCE) && ./bootstrap.sh --prefix=$(BOOST_INSTALL_PATH)

#
# Step 2 of compiling boost from source is running the b2 tool
# This target will configure the b2 tool to use a cross compiler and run it
#
$(BOOST_INSTALL_PATH)/.touch: $(BOOST_SOURCE)/b2
ifneq (desktop,$(MAKECMDGOALS))
	printf "using gcc : arm : $(abspath $(TOOLCHAIN_BIN)/arm-linux-gnueabihf-g++) ;" > $(BOOST_SOURCE)/user-config.jam
	cd $(BOOST_SOURCE) && ./b2 install $(BOOST_REQUIRED_LIBRARIES) --prefix=$(BOOST_INSTALL_PATH) toolset=gcc-arm --user-config=./user-config.jam
else
	printf "" > $(BOOST_SOURCE)/user-config.jam
	cd $(BOOST_SOURCE) && ./b2 install $(BOOST_REQUIRED_LIBRARIES) --prefix=$(BOOST_INSTALL_PATH) toolset=gcc --user-config=./user-config.jam
endif
	touch $@

#
# Catch all rule for extracting files from .tar.gz
#
%/.touch: %.tar.gz
	@printf "extracting %s to %s\n" $@ $?
	mkdir -p $(dir $@)
	tar -xvf $? --strip-components 1 -C $(dir $@)
	touch $@

#
# Catch all rule for downloading tar.gz files from links stored in '.wget' files
#
%.tar.gz : %.wget
	wget $(shell cat $?) -O $@ --show-progress
	touch -m $@

#
# Catch all rule for compiling source files
#
$(OUTPUT_DIR)/%.o: $(SOURCE_DIR)/%.cpp
	@mkdir -p $(OUTPUT_DIR)
	$(CXX) $(CXXFLAGS) -I$(BOOST_INCLUDE_PATH) -c $? -o $@

/usr//.touch:
# do nothing because this directory is managed by system package manager