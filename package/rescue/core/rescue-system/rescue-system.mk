################################################################################
#
# REG Rescue System
#
################################################################################

RESCUE_SYSTEM_SOURCE=

RESCUE_SYSTEM_VERSION = 0.5
RESCUE_SYSTEM_DATE_TIME = $(shell date "+%Y/%m/%d %H:%M")
RESCUE_SYSTEM_DATE = $(shell date "+%Y/%m/%d")
RESCUE_SYSTEM_DEPENDENCIES =

ifeq ($(BR2_PACKAGE_RESCUE_TARGET_AARCH64),y)
	RESCUE_SYSTEM_ARCH=aarch64
else ifeq ($(BR2_PACKAGE_RESCUE_TARGET_ARMV7),y)
	RESCUE_SYSTEM_ARCH=armv7
else ifeq ($(BR2_PACKAGE_RESCUE_TARGET_ARMHF),y)
	RESCUE_SYSTEM_ARCH=armhf
else ifeq ($(BR2_PACKAGE_RESCUE_TARGET_RISCV64),y)
	RESCUE_SYSTEM_ARCH=riscv
else ifeq ($(BR2_PACKAGE_RESCUE_TARGET_X86_64),y)
	RESCUE_SYSTEM_ARCH=x86_64
else
	RESCUE_SYSTEM_ARCH=unknown
endif

ifneq (,$(findstring dev,$(RESCUE_SYSTEM_VERSION)))
    RESCUE_SYSTEM_COMMIT = "-$(shell cd $(BR2_EXTERNAL_RESCUE_PATH) && git rev-parse --short HEAD)"
else
    RESCUE_SYSTEM_COMMIT =
endif

define RESCUE_SYSTEM_INSTALL_TARGET_CMDS

	# version/arch
	mkdir -p $(TARGET_DIR)/usr/share/batocera
	echo -n "$(RESCUE_SYSTEM_ARCH)" > $(TARGET_DIR)/usr/share/batocera/batocera.arch
	echo $(RESCUE_SYSTEM_VERSION)$(RESCUE_SYSTEM_COMMIT) $(RESCUE_SYSTEM_DATE_TIME) > $(TARGET_DIR)/usr/share/batocera/batocera.version

	# datainit
#	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/system
#	cp $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/batocera.conf $(TARGET_DIR)/usr/share/batocera/datainit/system

	# batocera-boot.conf
#	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/batocera-boot.conf $(BINARIES_DIR)/batocera-boot.conf

	# mounts
	mkdir -p $(TARGET_DIR)/boot $(TARGET_DIR)/overlay $(TARGET_DIR)/userdata

	# variables
	mkdir -p $(TARGET_DIR)/etc/profile.d
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/xdg.sh $(TARGET_DIR)/etc/profile.d/xdg.sh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/dbus.sh $(TARGET_DIR)/etc/profile.d/dbus.sh

	# list of modules that doesnt like suspend
	mkdir -p $(TARGET_DIR)/etc/pm/config.d
	echo 'SUSPEND_MODULES="rtw88_8822ce snd_pci_acp5x"' > $(TARGET_DIR)/etc/pm/config.d/config
    
    # Other scripts needed
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/batocera-mount $(TARGET_DIR)/usr/bin/
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_RESCUE_PATH)/package/rescue/core/rescue-system/batocera-part $(TARGET_DIR)/usr/bin/

endef

$(eval $(generic-package))
