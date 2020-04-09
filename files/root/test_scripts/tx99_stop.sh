#!/bin/sh

killall lanradio

set -e
set -x

echo 0  > /sys/kernel/debug/ieee80211/phy0/ath9k/tx99
ip link set moni0 down
iw dev moni0 del
