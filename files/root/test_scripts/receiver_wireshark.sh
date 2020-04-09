#!/bin/bash

set -x
#set -e

device="10.0.197.105"
#interface="wlan0"
#phy="phy0"
#frequency="5890"

ssh root@${device} "ip link set wlan0 down"
ssh root@${device} "echo 0xFFFFFFFF > /sys/kernel/debug/ieee80211/phy0/ath9k/debug"
ssh root@${device} "iw reg set KL"
ssh root@${device} "iw phy phy0 set antenna 1 1"
ssh root@${device} "iw dev wlan0 set type monitor"
ssh root@${device} "ip link set wlan0 up"
ssh root@${device} "iw dev wlan0 set freq 5890 10"
ssh root@${device} "iw dev wlan0 set bitrates legacy-5 12"
#ssh root@${device} "echo 63 > /sys/kernel/debug/ieee80211/phy0/ath9k/forced_txpower"

ssh root@${device} "tcpdump -i wlan0 -w -" | wireshark-gtk -k -l -i -



#ssh root@${device} "ip link set ${interface} down"
#ssh root@${device} "iw dev mon0 del"
#ssh root@${device} "iw dev ${interface} set type ocb"
#ssh root@${device} "ip link set ${interface} up"
#ssh root@${device} "iw dev ${interface} ocb join ${frequency} 10MHZ"
#ssh root@${device} "ifconfig ${interface} up"
#ssh root@${device} "iw phy ${phy} interface add mon0 type monitor"
#ssh root@${device} "ifconfig mon0 up"

#ssh root@${device} "tshark -i mon0 -F pcap -w -" | wireshark-gtk -k -l -i -

