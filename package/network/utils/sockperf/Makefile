#
# Copyright (C) 2018 CCS-Labs.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sockperf
PKG_VERSION:=3.3
PKG_RELEASE:=1

PKG_LICENSE_FILES:=LICENSE

PKG_MAINTAINER:=Florian Klingler <klingler@ccs-labs.org>

#PKG_SOURCE:=$(PKG_NAME)-v$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=http://dist.libuv.org/dist/v$(PKG_VERSION)/
#PKG_HASH:=ab9eb5355eb868e970a02022e0371d819251df6bbb88aada630cfcf8ac7b1c9b

PKG_SOURCE:=$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Mellanox/sockperf/archive/
PKG_MD5SUM:=d945ca56052eb7feba6d880237ef2e0e

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/sockperf
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Sockperf
  URL:=https://github.com/Mellanox/sockperf
  DEPENDS:=+libpthread +librt +libstdcpp
endef

define Package/sockperf/description
 Sockperf description
endef

define Build/Configure
	( cd $(PKG_BUILD_DIR); sed -i -e '/backtrace/d' configure.ac; sed -i -e '/execinfo/d' src/os_abstract.h; sed -i -e '/backtrace/d' src/common.cpp; sed -i -e '63,70d' src/os_abstract.cpp; sed -i -e '102d;104d' src/Ticks.h; sed -i -e '40d;43d;46d' src/vma-redirect.h; ./autogen.sh )
	$(call Build/Configure/Default)
endef

#define Build/InstallDev
#	$(INSTALL_DIR) $(1)/usr/include/
#	$(CP) \
#		$(PKG_INSTALL_DIR)/usr/include/* \
#		$(1)/usr/include/
#
#	$(INSTALL_DIR) $(1)/usr/lib
#	$(CP) \
#		$(PKG_INSTALL_DIR)/usr/lib/libuv.so* \
#		$(1)/usr/lib/
#	$(CP) \
#		$(PKG_INSTALL_DIR)/usr/lib/libuv.a \
#		$(1)/usr/lib/
#
#	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
#	$(CP) \
#		$(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libuv.pc \
#		$(1)/usr/lib/pkgconfig/
#endef

define Package/sockperf/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/bin/sockperf \
		$(1)/usr/bin/
endef

$(eval $(call BuildPackage,sockperf))
