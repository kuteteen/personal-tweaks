ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Touchr
Touchr_FILES = Tweak.x
Touchr_FRAMEWORKS = IOKit
Touchr_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
