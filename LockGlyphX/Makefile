ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockGlyphX
LockGlyphX_FILES = Tweak.x
LockGlyphX_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
