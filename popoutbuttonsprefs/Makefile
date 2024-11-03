TARGET := iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = popoutbuttonsprefs

popoutbuttonsprefs_FILES = POBRootListController.m
popoutbuttonsprefs_FRAMEWORKS = UIKit
popoutbuttonsprefs_PRIVATE_FRAMEWORKS = Preferences
popoutbuttonsprefs_INSTALL_PATH = /Library/PreferenceBundles
popoutbuttonsprefs_CFLAGS = -fobjc-arc
popoutbuttonsprefs_LIBRARIES = gcuniversal

include $(THEOS_MAKE_PATH)/bundle.mk
