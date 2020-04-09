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
packetIntvl=200
packetRateIdx=5
packetNumber=10
expno=0
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

./_setup_interface_ocb_mon.sh ${channelFreq} ${channelBW} 192.168.99.2

set +x
set +e

echo "#########################################################################"
echo "#########################################################################"
echo "# Pathloss measurements (TX)"
echo "# Channel frequency: ${channelFreq} MHz"
echo "# Channel bandwidth: ${channelBW} MHz"
echo "# Packet data rate idx: ${packetRateIdx} (0 = 54, 1 = 48, 2 = 36, 3 = 24, 4 = 18, 5 = 12, 6 = 9, 7 = 11, 8 = 5.5, 9 = 2, 10 = 1; (in MBit/s); holds for 20 MHz channels, half/quarter for 10/5 MHz channels;)"
echo "# ${packetIntvl} ms between each packet, ${packetNumber} packets to be sent in total (0=infinite)"
echo "#########################################################################"
echo "#########################################################################"
echo ""

killall gpslogger  2> /dev/null
#killall gpsd 2> /dev/null
sleep 2
#gpsd -n ${gpsdev}
sleep 2

killall sockperf 2> /dev/null
killall iperf 2> /dev/null

trap "killall rsseye 2> /dev/null; killall sockperf 2> /dev/null; killall iperf 2> /dev/null" SIGINT SIGTERM
stty -echoctl

mkdir -p ${resultsdir}/${campaign}
gpslogger --export ${resultsdir}/${campaign}/gpslogger_tx.csv 2> /dev/null &

while true
do
  echo "Enter experiment number and press enter to start a new measurement (or -1 to exit)"
  read -e -p "Expno: " -i "${expno}" expno

  if [ ${expno} == -1 ]; then
    echo "Exiting..."
    killall iperf 2> /dev/null
    killall sockperf 2> /dev/null
    killall rsseye 2> /dev/null
    killall gpslogger 2> /dev/null
#    killall gpsd 2> /dev/null
    exit
  fi

  echo "Starting measurement expno ${expno}"
  killall rsseye 2> /dev/null
  set -x
  rsseye -s -t ${packetIntvl} -m ${packetRateIdx} -a ${packetNumber} -e ${expno} -b ${channelBW} -i moni0
  set +x
  echo "Done"

  ##############################

  echo "Starting sockperf (Client)"
  killall sockperf 2> /dev/null
  sockperf under-load --tcp -i 192.168.99.1 -t 10 --mps=max --msg-size 1000 --full-log ${resultsdir}/${campaign}/sockperf_client_exp-${expno}.csv
  echo "Done" 

  ##############################

  echo "Starting iperf (Client)"
  killall iperf 2> /dev/null
  iperf -c 192.168.99.1 -t 10 -y C -i 1 > ${resultsdir}/${campaign}/iperf_client_exp-${expno}._csv
  head -n -1 ${resultsdir}/${campaign}/iperf_client_exp-${expno}._csv > ${resultsdir}/${campaign}/iperf_client_exp-${expno}.csv
  echo "Done" 

  echo "Inform that experiment is over (Walkie-Talkie) -- press Enter to continue"
  read

  ((expno++))
done
