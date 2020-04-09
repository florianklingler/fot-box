# This file is part of CCS-Labs.org.
#
# FOT-Box is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# FOT-Box is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Lanradio.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
# Florian Klingler <klingler@ccs-labs.org>
# Michele Segata <michele.segata@unibz.it>

include $(TOPDIR)/rules.mk

PKG_NAME:=resseye
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

PKG_BUILD_DEPENDS:=boost

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk


define Package/rsseye
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+boost +boost-program_options +protobuf +libprotobuf-c +libzmq +kmod-ath +kmod-ath5k +kmod-ath9k +iw +libpcap +libgps +gpsd
  TITLE:=simple app to send/receive IEEE 802.11 Frames and gather GPS information
  MAINTAINER:=Florian Klingler <klingler@ccs-labs.org>
endef

define Package/rsseye/description
	simple app to send/receive IEEE 802.11 Frames together with GPS information to measure communication distance
endef

define Package/rsseye/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rsseye $(1)/usr/bin/
endef

$(eval $(call BuildPackage,rsseye))
