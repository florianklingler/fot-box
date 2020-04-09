#!/bin/sh

if [ $# != 4 ]; then
	echo "usage: <antenna (1,2,3)> <tx power (half dBm)> <channel> <bandwidth>"
	#exit 1
	echo "using defaults: 1 20 178 10"
	ant=1
	pwr=20
	chn=178
	bwd=10
else
	ant=$1
	pwr=$2
	chn=$3
	bwd=$4
fi

./tx99_stop.sh &> /dev/null

set -e
set -x

echo 0xFFFFFFFF > /sys/kernel/debug/ieee80211/phy0/ath9k/debug

iw reg set KL
iw phy phy0 set antenna $ant $ant
iw phy phy0 interface add moni0 type monitor flags active
ip link set moni0 up
#iw dev moni0 set bitrates legacy-5 6
iw dev moni0 set channel $chn $bwd

echo $pwr > /sys/kernel/debug/ieee80211/phy0/ath9k/tx99_power
echo 1 > /sys/kernel/debug/ieee80211/phy0/ath9k/tx99

cat /sys/kernel/debug/ieee80211/phy0/ath9k/tx99_power
