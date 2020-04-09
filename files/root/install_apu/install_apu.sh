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
	dd if=/tmp/lede-x86-generic-combined-squashfs.img of=/dev/sda
	sync

	blockdev --rereadpt /dev/sda
	echo 'type=83' | sfdisk --append /dev/sda
	sync
	blockdev --rereadpt /dev/sda
	mkfs.ext4 -F /dev/sda3
	sync
	
	# mounting jffs2 parition rw does somehow not work... thus we enable mounts in a separate script to be executed by the user after reboot
	
	#mount /dev/sda2 /mnt
	
	#BLKINFO=$(block info | grep sda3 | awk '{split($2,a,"\""); print a[2]}')
	#echo "
	#config 'global'
	#option	anon_swap	'0'
	#option	anon_mount	'0'
	#option	auto_swap	'1'
	#option	auto_mount	'1'
	#option	delay_root	'5'
	#option	check_fs	'0'" > /mnt/etc/config/fstab

	#echo "config 'mount'
	#option	target	'/data'
	#option	uuid	'$(BLKINFO)'
	#option	enabled	'1'" >> /mnt/etc/config/fstab

	#sync
	#umount /dev/sda2
	#sync

	echo "DONE: Rebooting..."
	reboot
else
        echo "WARNING: Wrong hostname set"
        echo "   use 'echo install_apu > /proc/sys/kernel/hostname'"
        echo "   to allow installation on this APU/ALIX Box"
        echo "ALL DATA WILL BE LOST!"
fi
