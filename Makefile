ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = Swappon
Swappon_FILES = Tweak.xm
Swappon_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
