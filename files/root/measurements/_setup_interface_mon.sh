#!/bin/sh

if [ $# != 2 ]; then
	echo "missing arguments: <Freq> <BW>"
	exit 1
fi

ip link set wlan0 down

set -e
set -x

echo "0xFFFFFFFF" > /sys/kernel/debug/ieee80211/phy0/ath9k/debug

iw reg set KL
iw phy phy0 set antenna 1 1
#iw phy phy0 interface add moni0 type monitor flags active
#ip link set moni0 up
iw dev wlan0 set type monitor
ip link set wlan0 up
iw dev wlan0 set freq $1 $2
iw dev wlan0 set bitrates legacy-5 6 9 12 18 24 36 48 54
w dev wlan0 set txpower fixed 3600
echo 63 > /sys/kernel/debug/ieee80211/phy0/ath9k/forced_txpower

