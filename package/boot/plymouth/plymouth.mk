#############################################################
#
# Plymouth
#
#############################################################

PLYMOUTH_VERSION = 26.134.222
PLYMOUTH_SITE = https://gitlab.freedesktop.org/plymouth/plymouth.git
PLYMOUTH_SITE_METHOD = git
PLYMOUTH_DEPENDENCIES += libdrm libpng libevdev freetype libxkbcommon xkeyboard-config gettext dejavu
PLYMOUTH_PATH = $(BR2_EXTERNAL_RESCUE_PATH)/package/boot/plymouth

PLYMOUTH_CONF_OPTS  = -Dgtk=disabled -Dsystemd-integration=false -Ddocs=false
# Text through label-freetype instead of label-pango: drops pango, cairo,
# harfbuzz, fontconfig, fribidi, pixman and glib (~8 MB unpacked). Without
# fontconfig, label-freetype loads /usr/share/fonts/Plymouth.ttf (see
# PLYMOUTH_FONT below); it only uses a bold face for rich-text markup, which
# the theme does not use.
PLYMOUTH_CONF_OPTS += -Dpango=disabled -Dfreetype=enabled
PLYMOUTH_CONF_OPTS += -Dlogo=/usr/share/pixmaps/reglinux_logo.png

define PLYMOUTH_LOGO
	mkdir -p $(TARGET_DIR)/usr/share/pixmaps/
	cp $(PLYMOUTH_PATH)/images/reglinux_logo.png $(TARGET_DIR)/usr/share/pixmaps/
endef

define PLYMOUTH_INITD
	$(INSTALL) -m 0755 $(PLYMOUTH_PATH)/config/S002plymouth $(TARGET_DIR)/etc/init.d/
	$(INSTALL) -m 0644 $(PLYMOUTH_PATH)/config/plymouthd.conf $(TARGET_DIR)/etc/plymouth/plymouthd.conf

	# Themes
	rm -rf $(TARGET_DIR)/usr/share/plymouth/themes/*
	cp -r $(PLYMOUTH_PATH)/themes/* $(TARGET_DIR)/usr/share/plymouth/themes/
endef

# One font: label-freetype's fallback path, nothing else under /usr/share/fonts.
# At target-finalize, after dejavu (and anything else) has installed its fonts.
define PLYMOUTH_FONT
	mv -f $(TARGET_DIR)/usr/share/fonts/dejavu/DejaVuSans.ttf $(TARGET_DIR)/usr/share/fonts/Plymouth.ttf 2>/dev/null || \
		test -f $(TARGET_DIR)/usr/share/fonts/Plymouth.ttf
	rm -rf $(TARGET_DIR)/usr/share/fonts/dejavu
endef

PLYMOUTH_PRE_CONFIGURE_HOOKS += PLYMOUTH_LOGO
PLYMOUTH_TARGET_FINALIZE_HOOKS += PLYMOUTH_FONT
PLYMOUTH_POST_INSTALL_TARGET_HOOKS += PLYMOUTH_INITD

$(eval $(meson-package))
