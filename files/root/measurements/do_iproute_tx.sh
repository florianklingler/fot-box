#!/bin/bash

stty -echoctl

source _settings.sh

echo "-------------------------------------------------------------------------"
echo "| IP Routing (TX-Side)"
echo "|"
echo "| Freq: ${freq} MHz"
echo "| Bandwidth: ${bandwidth} MHz"
echo "| gw: ${gw_tx}, netmask: 255.255.255.0"
echo "_________________________________________________________________________"

killall ssh

if [ $ssh_connect_third -ne 0 ]; then
	
	udhcpc -i $internet_interface
	ssh -N -f setup-measurements-tx
	if [ $? -ne 0 ]; then

		echo " failed to setup portforwardings; check internet connection"
		killall ssh
		exit 1
	fi
fi

echo -e '\n'
echo "Press enter to configure interfaces and ip routing"
read

echo "Configuring Interfaces..."

./_setup_interface_ocb_mon_ip-route.sh ${freq} ${bandwidth} ${ip_tx} ${ip_rx} ${nw_rx}
#arp -i $wifi_interface -s ${ip_rx} ${mac_rx}
ip neigh add ${ip_rx} lladdr ${mac_rx} nud permanent dev $wifi_interface

