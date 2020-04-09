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

host_tx="measurements-tx"
host_rx="localhost"

source ../_settings.sh

if [[ $HOSTNAME != apu4 && $HOSTNAME != apu5 ]]; then
	echo "this script should only be executed on an APU Box"
	exit 1
fi

if [ -d ${resultsdir}/copied_results ]; then
	echo "folder ${resultsdir}/copied_results already exists, exiting..."
	exit 1
fi

mkdir -p ${resultsdir}/copied_results/host_tx
mkdir -p ${resultsdir}/copied_results/host_rx

rsync -pPax --exclude '*.pcap' --exclude '*copied_results*' root@$host_tx:$resultsdir/* ${resultsdir}/copied_results/host_tx/
rsync -pPax --exclude '*.pcap' --exclude '*copied_results*' root@$host_rx:$resultsdir/* ${resultsdir}/copied_results/host_rx/
