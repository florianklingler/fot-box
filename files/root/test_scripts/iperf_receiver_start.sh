#!/bin/sh

#if [ $# == 0 ]; then
#	echo "missing argument tx power (half dBm)"
#	exit 1
#fi

killall lanradio
killall iperf
killall iperf3
#killall gpsd
#ip link set moni0 down
#iw dev moni0 del
ip link set wlan0 down

set -e
set -x

echo 0xFFFFFFFF > /sys/kernel/debug/ieee80211/phy0/ath9k/debug

iw reg set KL
iw phy phy0 set antenna 1 1
#iw phy phy0 interface add moni0 type monitor flags active
#ip link set moni0 up
iw dev wlan0 set type ocb
ip link set wlan0 up
iw dev wlan0 ocb join 5890 10MHz
iw dev wlan0 set bitrates legacy-5 6 9 12 18 24 36 48 54
echo 63 > /sys/kernel/debug/ieee80211/phy0/ath9k/forced_txpower
echo 0 > /sys/kernel/debug/ieee80211/phy0/ath9k/airtime_flags

#gpsd -n /dev/ttyACM0
ifconfig wlan0 192.168.99.1
iperf3 -s
