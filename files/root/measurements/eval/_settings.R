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

use_maxdist <- F
maxdist <- 1800
use_maxindex <- F
maxindex <- 1000
use_realdist <- T
draw_boxplots=F

max_rss <- 3
min_rss <- -100
max_delay <- 300
max_datarate <- 17

map_x <- 2800
map_y <- 2800
map_text_exp_x <- 0.05
map_text_exp_y <- 0
map_color_rsseye <- F
map_dbvals_rsseye <- F
# if map_online=F then a file map.osm needs to be present, otherwise get openstreetmap data from internet
map_online <- T
map_spacing_x <- 25
map_spacing_y <- 25
# currently disabled: map_ticks_by
map_ticks_by <- 5
