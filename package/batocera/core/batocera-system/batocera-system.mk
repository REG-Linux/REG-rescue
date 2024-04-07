################################################################################
#
# batocera.linux System
#
################################################################################

BATOCERA_SYSTEM_SOURCE=

BATOCERA_SYSTEM_VERSION = 40-dev
BATOCERA_SYSTEM_DATE_TIME = $(shell date "+%Y/%m/%d %H:%M")
BATOCERA_SYSTEM_DATE = $(shell date "+%Y/%m/%d")
BATOCERA_SYSTEM_DEPENDENCIES =

ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_AARCH64),y)
	BATOCERA_SYSTEM_ARCH=aarch64
else ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_ARMV7),y)
	BATOCERA_SYSTEM_ARCH=armb7
else ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_ARMHF),y)
	BATOCERA_SYSTEM_ARCH=armhf
else ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_RISCV),y)
	BATOCERA_SYSTEM_ARCH=riscv
else ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_X86_64),y)
	BATOCERA_SYSTEM_ARCH=x86_64
else
	BATOCERA_SYSTEM_ARCH=unknown
endif

ifneq (,$(findstring dev,$(BATOCERA_SYSTEM_VERSION)))
    BATOCERA_SYSTEM_COMMIT = "-$(shell cd $(BR2_EXTERNAL_BATOCERA_PATH) && git rev-parse --short HEAD)"
else
    BATOCERA_SYSTEM_COMMIT =
endif

define BATOCERA_SYSTEM_INSTALL_TARGET_CMDS

	# version/arch
	mkdir -p $(TARGET_DIR)/usr/share/batocera
	echo -n "$(BATOCERA_SYSTEM_ARCH)" > $(TARGET_DIR)/usr/share/batocera/batocera.arch
	echo $(BATOCERA_SYSTEM_VERSION)$(BATOCERA_SYSTEM_COMMIT) $(BATOCERA_SYSTEM_DATE_TIME) > $(TARGET_DIR)/usr/share/batocera/batocera.version

	# datainit
	mkdir -p $(TARGET_DIR)/usr/share/batocera/datainit/system
	cp $(BR2_EXTERNAL_BATOCERA_PATH)/package/batocera/core/batocera-system/batocera.conf $(TARGET_DIR)/usr/share/batocera/datainit/system

	# batocera-boot.conf
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_BATOCERA_PATH)/package/batocera/core/batocera-system/batocera-boot.conf $(BINARIES_DIR)/batocera-boot.conf

	# mounts
	mkdir -p $(TARGET_DIR)/boot $(TARGET_DIR)/overlay $(TARGET_DIR)/userdata

	# variables
	mkdir -p $(TARGET_DIR)/etc/profile.d
	cp $(BR2_EXTERNAL_BATOCERA_PATH)/package/batocera/core/batocera-system/xdg.sh $(TARGET_DIR)/etc/profile.d/xdg.sh
	cp $(BR2_EXTERNAL_BATOCERA_PATH)/package/batocera/core/batocera-system/dbus.sh $(TARGET_DIR)/etc/profile.d/dbus.sh

	# list of modules that doesnt like suspend
	mkdir -p $(TARGET_DIR)/etc/pm/config.d
	echo 'SUSPEND_MODULES="rtw88_8822ce snd_pci_acp5x"' > $(TARGET_DIR)/etc/pm/config.d/config
endef

$(eval $(generic-package))
