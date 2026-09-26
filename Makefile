TARGET := iphone:15.6:15.0
ARCHS = arm64e arm64
INSTALL_TARGET_PROCESSES =

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = SlipperyUIKit
SlipperyUIKit_FILES = SlipperyPrefsHeaderView.m SlipperyPrefsFooterView.m SlipperyLink.m
SlipperyUIKit_PUBLIC_HEADERS = SlipperyPrefsHeaderView.h SlipperyPrefsFooterView.h SlipperyLink.h
SlipperyUIKit_FRAMEWORKS = UIKit
SlipperyUIKit_PRIVATE_FRAMEWORKS = Preferences
SlipperyUIKit_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
SlipperyUIKit_INSTALL_PATH = /Library/Frameworks
SlipperyUIKit_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/framework.mk
