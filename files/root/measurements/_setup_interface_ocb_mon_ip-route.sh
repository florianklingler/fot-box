#!/bin/sh

if [ $# != 5 ]; then
	echo "missing arguments: <Freq> <BW> <IP> <Remote-IP> <Remote-Network>"
	exit 1
fi

ip link set wlan0 down
ip link set moni0 down
iw dev moni0 del
ip link set moni1 down
iw dev moni1 del

set -e
set -x

echo "0xFFFFFFFF" > /sys/kernel/debug/ieee80211/phy0/ath9k/debug

iw reg set KL
iw phy phy0 set antenna 1 1
iw dev wlan0 set type ocb
ip link set wlan0 up
iw dev wlan0 ocb join $1 $2MHz
iw dev wlan0 set bitrates legacy-5 6 9 12 18 24 36 48 54
iw dev wlan0 set txpower fixed 3600
ifconfig wlan0 $3 netmask 255.255.255.0
iw phy phy0 interface add moni0 type monitor flags active
ip link set moni0 up
iw dev moni0 set bitrates legacy-5 6 9 12 18 24 36 48 54

iw phy phy0 interface add moni1 type monitor flags active
ip link set moni1 up
iw dev moni1 set bitrates legacy-5 6 9 12 18 24 36 48 54

echo 63 > /sys/kernel/debug/ieee80211/phy0/ath9k/forced_txpower

route add -net $5 netmask 255.255.255.0 gw $4
iptables -I FORWARD -i br-ext -j ACCEPT
iptables -I FORWARD -i wlan0 -j ACCEPT
