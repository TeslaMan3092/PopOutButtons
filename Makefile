TARGET := iphone:clang:17.0:13.0

export SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = PopOutButtons

PopOutButtons_FILES = $(wildcard *.x *.m )
PopOutButtons_CFLAGS = -fobjc-arc
PopOutButtons_LIBRARIES = gcuniversal 

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += popoutbuttonsprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
