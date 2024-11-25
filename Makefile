TARGET := iphone:clang:17.0:13.0
# TARGET = simulator:clang::16.0
# export ARCHS = x86_64 i386

export SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk
export ARCHS = arm64 arm64e
DEBUG = 0

# ADDITIONAL_LDFLAGS = -arch x86_64

include $(THEOS)/makefiles/common.mk

INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = PopOutButtons

PopOutButtons_FILES = $(wildcard *.x *.m )
PopOutButtons_CFLAGS = -fobjc-arc
PopOutButtons_LIBRARIES = gcuniversal 

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += popoutbuttonsprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@codesign -f -s - /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject

