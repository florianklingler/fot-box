#!/bin/sh

source _settings.sh

set -x

#ip link set $wifi_interface down
killall hostapd

set -e

hostapd -B $hostapd_file
ifconfig $wifi_interface $ip_tx
iw $wifi_interface set power_save off
