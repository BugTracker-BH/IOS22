TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

# Respring after install so injected apps reload the tweak.
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DisableWebViewStrongPassword

DisableWebViewStrongPassword_FILES = Tweak.x
DisableWebViewStrongPassword_CFLAGS = -fobjc-arc
DisableWebViewStrongPassword_FRAMEWORKS = WebKit

include $(THEOS_MAKE_PATH)/tweak.mk
