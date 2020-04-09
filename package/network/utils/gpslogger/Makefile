# This file is part of CCS-Labs.org.
#
# Lanradio is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Lanradio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Lanradio.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
# Florian Klingler <klingler@ccs-labs.org>
# Christoph Sommer <sommer@cms-labs.org>

include $(TOPDIR)/rules.mk

PKG_NAME:=gpslogger
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

#PKG_BUILD_DEPENDS:=boost

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk


define Package/gpslogger
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+libgps +gpsd
  TITLE:=gpslogger
  MAINTAINER:=Florian Klingler <klingler@ccs-labs.org>
endef

define Package/gpslogger/description
	gpslogger
endef

define Package/gpslogger/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/gpslogger $(1)/usr/bin/
endef

$(eval $(call BuildPackage,gpslogger))
