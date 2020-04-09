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

host_rx="10.0.197.105"

source ../_settings.sh

mkdir -p results/host_tx
mkdir -p results/host_rx

rsync -pPax --exclude '*.pcap' root@$host_rx:$resultsdir/copied_results/host_tx/* results/host_tx/
rsync -pPax --exclude '*.pcap' root@$host_rx:$resultsdir/copied_results/host_rx/* results/host_rx/

today=`date '+%Y_%m_%d__%H_%M_%S'`
touch archived_${today}
tar czvf results-${today}.tar.gz results archived_${today}
