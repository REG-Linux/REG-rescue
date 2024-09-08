################################################################################
#
# noto-sans-fonts
#
################################################################################

NOTO_SANS_FONTS_VERSION = f10dc31fb679345cf9ab0cc4fdca061d03a78b82
NOTO_SANS_FONTS_SITE = $(call github,notofonts,NotoSans,$(NOTO_SANS_FONTS_VERSION))

NOTO_SANS_FONTS_TARGET_DIR=$(TARGET_DIR)/usr/share/fonts/truetype/noto

define NOTO_SANS_FONTS_INSTALL_TARGET_CMDS
	mkdir -p $(NOTO_SANS_FONTS_TARGET_DIR)
	cp $(@D)/fonts/ttf/hinted/instance_ttf/NotoSans-Bold.ttf $(NOTO_SANS_FONTS_TARGET_DIR)
	cp $(@D)/fonts/ttf/hinted/instance_ttf/NotoSans-Regular.ttf $(NOTO_SANS_FONTS_TARGET_DIR)
endef

$(eval $(generic-package))
