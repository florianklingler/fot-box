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

IFS=

set -e
if [[ $HOSTNAME = install_apu ]]; then
	echo "Downloading firmware from tftp..."
	atftp --get -r images/lede-x86-generic-combined-squashfs.img -l /tmp/lede-x86-generic-combined-squashfs.img 10.0.197.200
	echo "Have you backed up data/results? y/n"
	read -n 1 key
	if [ "$key" != "y" ]; then
		echo "Exiting... (nothing changed)"
	fi
	echo "Should we flash firmware? y/n"
	read -n 1 key
	if [ "$key" != "y" ]; then
		echo "Exiting... (nothing changed)"
	fi
	set -x
	sysupgrade -c /tmp/lede-x86-generic-combined-squashfs.img
	echo "DONE: Rebooting..."
else
        echo "WARNING: Wrong hostname set"
        echo "   use 'echo install_apu > /proc/sys/kernel/hostname'"
        echo "   to allow installation on this APU/ALIX Box"
        echo "ALL DATA WILL BE LOST!"
fi
