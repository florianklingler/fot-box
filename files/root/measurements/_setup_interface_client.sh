#!/bin/sh

source _settings.sh


set -x
#ip link set $wifi_interface down

set -e


wpa_supplicant -Dnl80211 -i$wifi_interface -c$supplicant_file -B
ifconfig $wifi_interface $ip_rx
iw $wifi_interface set power_save off
