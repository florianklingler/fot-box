# This file is part of CCS-Labs.org.
#
# FOT-Box is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Lanradio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Lanradio.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
# Florian Klingler <klingler@ccs-labs.org>

#!/bin/bash

stty -echoctl

source _settings.sh

echo "-------------------------------------------------------------------------"
echo "| Measurements (TX-Side)"
echo "|"
echo "| Freq: ${freq} MHz"
echo "| Bandwidth: ${bandwidth} MHz"
echo "_________________________________________________________________________"

killall ssh
ssh-add /root/.ssh/${ssh_priv_key_file}

if [ $ssh_connect_third -ne 0 ]; then
	
	#udhcpc -i $internet_interface
	#ssh -N -f setup-measurements-tx
	#if [ $? -ne 0 ]; then
	#
	#	echo " failed to setup portforwardings; check internet connection"
	#	killall ssh
	#	exit 1
	#fi
	./_connect_tx.sh no-key
fi

echo -e '\n'
echo "Press enter to configure interfaces and start measurement campaign"
read

echo "Configuring Interfaces..."

./_setup_interface_ap.sh ${freq} ${bandwidth} ${ip_tx}
#arp -i $wifi_interface -s ${ip_rx} ${mac_rx}
#ip neigh add ${ip_rx} lladdr ${mac_rx} nud permanent dev $wifi_interface

