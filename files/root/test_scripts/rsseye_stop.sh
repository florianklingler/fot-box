#!/bin/sh

killall rsseye
killall gpsd
#ip link set moni0 down
#iw dev moni0 del 
ip link set wlan0 down

set -e
set -x

