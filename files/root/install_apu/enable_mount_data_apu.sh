# This file is part of CCS-Labs.org.
#
# FOT-Box is free software: you can redistribute it and/or modify
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

#!/bin/bash

set -e
if [[ $HOSTNAME = install_apu ]]; then
	set -x
	BLKINFO=$(block info | grep sda3 | awk '{split($2,a,"\""); print a[2]}')

	echo "config 'mount'
	option	target	'/data'
	option	uuid	'${BLKINFO}'
	option	enabled	'1'" >> /etc/config/fstab

	sync

	echo "DONE: Rebooting..."
	reboot
else
        echo "WARNING: Wrong hostname set"
        echo "   use 'echo install_apu > /proc/sys/kernel/hostname'"
        echo "   to allow installation on this APU/ALIX Box"
        echo "ALL DATA WILL BE LOST!"
fi
