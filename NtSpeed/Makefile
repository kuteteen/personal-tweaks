ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NtSpeed
NtSpeed_FILES = Tweak.m
NtSpeed_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
