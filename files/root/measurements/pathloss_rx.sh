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


channelFreq=5890
channelBW=10
dist=0
distincr=10
gpsdev="/dev/ttyACM0"
resultsdir="/data/results"

if [ $# != 1 ]; then
	echo "missing arguments: <Measurement-Campaign-Name>"
	exit 1
fi
campaign=$1

if [ -d "${resultsdir}/${campaign}" ]; then
  echo "results for campaign '${campaign}' already exist. Check name!"
  exit 1
fi

echo "Configuring Interfaces..."

./_setup_interface_ocb_mon.sh ${channelFreq} ${channelBW} 192.168.99.1

set +x
set +e

echo "#########################################################################"
echo "#########################################################################"
echo "# Pathloss measurements (RX)"
echo "# Channel frequency: ${channelFreq} MHz"
echo "# Channel bandwidth: ${channelBW} MHz"
echo "#########################################################################"
echo "#########################################################################"
echo ""

killall gpslogger 2> /dev/null
#killall gpsd 2> /dev/null
sleep 2
#gpsd -n ${gpsdev}
sleep 2

killall sockperf 2> /dev/null
killall iperf 2> /dev/null

trap "killall rsseye 2> /dev/null" SIGINT SIGTERM
stty -echoctl

mkdir -p ${resultsdir}/${campaign}
gpslogger --export ${resultsdir}/${campaign}/gpslogger_rx.csv 2> /dev/null &

sockperf server --tcp > /dev/null &
iperf -s > /dev/null &

while true 
do
  echo "Enter approximate distance and press enter to start a new measurement (or -1 to exit)"
  read -e -p "distance in m: " -i "${dist}" dist

  if [ ${dist} == -1 ]; then
    echo "Exiting..."
    killall rsseye 2> /dev/null
    killall gpslogger 2> /dev/null
#    killall gpsd 2> /dev/null
    exit
  fi

  if [ -f "${resultsdir}/${campaign}/${dist}m.csv" ]; then
  echo "results for '${campaign}/${dist}m.csv' already exist. Check distance!"
  continue
  fi

  echo "Starting measurement with dist ${dist} m"
  killall rsseye 2> /dev/null
  set -x
  rsseye -r -i moni0 > ${resultsdir}/${campaign}/${dist}m.csv
  set +x
  echo "Done"

  echo "Waiting for sockperf and iperf to finish -- wait for OK (Walkie-Talkie) from TX and press Enter to continue"
  read

  ((dist+=distincr))
done
