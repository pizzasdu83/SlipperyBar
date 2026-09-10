TARGET := iphone:15.6:15.0
ARCHS = arm64e arm64
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SlipperyBar
SlipperyBar_FILES = Tweak.xm
SlipperyBar_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

BUNDLE_NAME = HomeBarTintPrefs
HomeBarTintPrefs_FILES = HBTPrefsListController.m HBTColorPickerController.m
HomeBarTintPrefs_INSTALL_PATH = /Library/PreferenceBundles
HomeBarTintPrefs_FRAMEWORKS = UIKit
HomeBarTintPrefs_PRIVATE_FRAMEWORKS = Preferences
HomeBarTintPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
