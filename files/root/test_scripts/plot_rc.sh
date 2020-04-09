#!/bin/sh

while true; do cat /sys/kernel/debug/ieee80211/phy0/netdev:wlan0/stations/*/rc_stats ; sleep 1; clear; done
