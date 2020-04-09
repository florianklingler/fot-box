#!/bin/bash

#### general configuration
#ssh_remote_server="192.168.99.104" # to start measurements
#ssh_remote_server="192.168.10.253" # to start measurements
ssh_remote_server="measurements-tx"
#ssh_remote_server="10.0.197.104"

ssh_connect_third=1
ssh_priv_key_file="klingler_measurements"
#autossh is broken at the moment
use_autossh=0
internet_interface="usb0"
resultsdir="/mnt/sda1" # absoulte path, without trailing slash
measurements_dir="/root/measurements" # absoulte path, without trailing slash
dist_increment=10
use_tcpdump=0 # set to 1 if every packet on rx/tx should be recorded in pcap files, Huge File Size!
do_beep=0

#5 GHz: wlan0
#2.4 GHz: wlan1
#60 GHz: wlan2

wifi_interface="wlan2"
hostapd_file="/root/measurements/conf/wlan2_hostapd.conf"
supplicant_file="/root/measurements/conf/wlan2_wpa_supplicant.conf"


#### /general configuration

#### IEEE 802.11 configuration
configure_interfaces=1
freq=5890 # in MHz
bandwidth=10 # 5,10, or 20 MHz
ip_tx=192.168.99.104
mac_tx="4C:5E:0C:17:FA:F2"
nw_tx=10.0.104.0
gw_tx=10.0.104.104
ip_rx=192.168.99.105
mac_rx="4C:5E:0C:17:FA:C1"
nw_rx=10.0.105.0
gw_rx=10.0.105.105


#### /IEEE 802.11 configuration

#### rsseye configuration
rsseye_intvl=10 # in ms
rsseye_numpackets=1000 # how many packets to send
rsseye_numpackets_infinite=0 # setting for sending infinite packets
rsseye_rateidx=7 # 0 = 54, 1 = 48, 2 = 36, 3 = 24, 4 = 18, 5 = 12, 6 = 9, 7 = 6; (in MBit/s); holds for 20 MHz channels, half/quarter for 10/5 MHz channels;)
#### /rsseye configuration

#### iperf udp configuration
iperf_udp_len=800
#### /iperf udp configuration

#### experiment configuration
do_exp_rsseye=0
do_exp_sockperf_tcp=1
do_exp_iperf_tcp=1
do_exp_sockperf_udp=1
do_exp_iperf_udp=1
do_exp_sweep=1
#### /experiment configuration

filename_gpslogger_rx="gpslogger_rx" # without .csv ending
filename_gpslogger_tx="gpslogger_tx" # without .csv ending

#filename_rsseye_tx="rsseye_tx" # without .csv ending
filename_rsseye_rx="rsseye_rx" # without .csv ending

filename_sockperf_tx="sockperf_tx" # without .csv ending
#filename_sockperf_rx="sockperf_rx" # without .csv ending

filename_iperf_tx="iperf_tx" # without .csv ending
filename_iperf_rx="iperf_rx" # without .csv ending

filename_sweep_tx="sweep_tx" # without .csv ending
filename_sweep_rx="sweep_rx" # without .csv ending
