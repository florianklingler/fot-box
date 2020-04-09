#!/bin/sh

#if [ $# == 0 ]; then
#	echo "missing argument tx power (half dBm)"
#	exit 1
#fi

killall lanradio
killall rsseye
killall gpsd
ip link set wlan0 down
#ip link set moni0 down
#iw dev moni0 del

set -e
set -x

echo 0xFFFFFFFF > /sys/kernel/debug/ieee80211/phy0/ath9k/debug

iw reg set KL
iw phy phy0 set antenna 1 1
#iw phy phy0 interface add moni0 type monitor flags active
#ip link set moni0 up
iw dev wlan0 set type monitor
ip link set wlan0 up
iw dev wlan0 set freq 5890 10
iw dev wlan0 set bitrates legacy-5 12
echo 63 > /sys/kernel/debug/ieee80211/phy0/ath9k/forced_txpower

gpsd -n /dev/ttyACM0
rsseye -s
