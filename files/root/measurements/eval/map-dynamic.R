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

source("_settings.R")

dina4 = 516
dpi = 72
width = .45

wi= 1.4 * dina4 / dpi / ( 1 / width)
he = 1.4 * dina4 / dpi / ( 1 / width) / (7/5) / 1.5

options(digits=12)
require(plyr)
require(geosphere)
library(osmar)
library(rgeos)
library(rgdal)
library(plotrix)

buildingColor <- "white"
buildingBorderColor <- "grey"
buildIntersectionCololor <- "darkgrey"



myps <- function(file, paper="special", width=7, height=5, family="Times") {
  postscript(file = paste(file, ".eps", sep=""), horizontal = FALSE, onefile = FALSE, paper=paper, width=width, height=height, family=family)
  done <- function() {
    graphics.off()
    system(paste("ps2pdf -dPDFSETTINGS=/prepress -dEPSCrop ", file, ".eps", sep=""))
  }
  return(done)
}

require('tikzDevice')
options(tikzLatexPackages=c(getOption('tikzLatexPackages'), "\\usepackage[utf8]{inputenc}", "\\usepackage[T1]{fontenc}", "\\usetikzlibrary{backgrounds}", "\\usepackage{amsmath}", "\\usepackage{amsthm}", "\\usepackage{amsfonts}", "\\usepackage{amssymb}"))
options(tikzDocumentDeclaration = "\\documentclass[10pt,conference,letterpaper]{IEEEtran}")
myps2 <- function(file, paper="special", width=6, height=4, family="Times") {
	tikz(paste(file, ".tex", sep=""), standAlone = TRUE, width=width*.83, height=height*.83)
	done <- function() {
		graphics.off()
		system(paste("pdflatex ", file, ".tex", sep=""))
	}
	return(done)
}


###
#
# get command line arguments and build filenames
#
##
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.name <- substr(script.name, 1, nchar(script.name)-2)
	
args <- commandArgs(trailingOnly = TRUE);
if (length(args) < 1) {
	error("missing arguments")
} else {
	campaign <- args[1]
}


load_data_realdist <- function (campaign, expno, dist) {

	rx_filename <- paste0("results/host_rx/", campaign, "/", expno, "/rsseye/rsseye_rx_expno-",expno,"_dist-",dist,".csv")

	rx <- read.delim(rx_filename ,sep=",")

	rcvT <- cbind(rx$rcv_gpsinfo.lon,rx$rcv_gpsinfo.lat)
	rxy <- project(rcvT, "+proj=utm +zone=32N +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
	rx$rx_X <- rxy[,1]
	rx$rx_Y <- rxy[,2]

	sndT <- cbind(rx$payload.gpsinfo.lon,rx$payload.gpsinfo.lat)
	txy <- project(sndT, "+proj=utm +zone=32N +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
	rx$tx_X <- txy[,1]
	rx$tx_Y <- txy[,2]


	data <- subset(rx, !is.na(rx_X) & !is.na(rx_Y) & !is.na(tx_X) & !is.na(tx_Y) & !is.na(frame_info.rcv_power))

	if(nrow(data) == 0) {
		return(data.frame())
	}

	data$real_dist <- sqrt((data$rx_X-data$tx_X)^2+(data$rx_Y-data$tx_Y)^2)
	
	data$campaign <- campaign
	data$expno <- expno
	data$dist <- dist

	data$mydist <- data$real_dist

	return(data)
}

arrowLine <- function(x, y, N=10, ...){
  lengths <- c(0, sqrt(diff(x)^2 + diff(y)^2))
  l <- cumsum(lengths)
  tl <- l[length(l)]
  el <- seq(0, to=tl, length=N+1)[-1]

  #plot(x, y, t="l", ...)
  lines(x, y, ...)

  for(ii in el){

    int <- findInterval(ii, l)
    xx <- x[int:(int+1)]
    yy <- y[int:(int+1)]

    ## points(xx,yy, col="grey", cex=0.5)

    dx <- diff(xx)
    dy <- diff(yy)
    new.length <- ii - l[int]
    segment.length <- lengths[int+1]

    ratio <- new.length / segment.length

    xend <- x[int] + ratio * dx
    yend <- y[int] + ratio * dy
    #points(xend,yend, col="white", pch=19)
    arrows(x[int], y[int], xend, yend, length=0.06, lwd=2)

  }
}

get_walls_matter <- function(rcvX, rcvY, sndX, sndY, poly, rssi_color) {

	l_x= c(sndX, rcvX)
	l_y = c(sndY, rcvY)

	l_l <- Line(cbind(l_x, l_y))
	l_ls <- Lines(list(l_l), ID="a")

	spls <- SpatialLines(list(l_ls), proj4string = CRS("+proj=utm +zone=32N +ellps=WGS84 +datum=WGS84 +units=m +no_defs")) # ellips rotations ellipsoid, datum=coordinaten, nodefs=keine defaultparameter, 

	lsdf <- SpatialLinesDataFrame(spls, data.frame(Z=c("a"), row.names=c("a")))

	inters <- gIntersection(poly, lsdf, byid=TRUE)

	walls_per_building <- 0
	if(length(inters) > 0) {
		walls_per_building <- lapply(slot(inters, "lines"), function(x) 2*length(slot(x, "Lines")))
	}
	walls_total <- Reduce("+",walls_per_building)
	#print(walls_total)

	#if(walls_total > 2) {
	#	print("more than 1 inters")
	#}
	matter <- 0
	if(walls_total > 0) {
		matter <- gLength(inters)
	}
	res <- c(walls_total, matter)

	plot(lsdf, col=rssi_color, add=TRUE)
	if(walls_total >= 2) {
		plot(inters, col=buildIntersectionCololor, add=TRUE, lwd=1)
	}
	#if(walls_total == 2) {
	#	plot(inters, col="black", add=TRUE, lwd=1)
	#} else if(walls_total == 4) {
	#	plot(inters, col="yellow", add=TRUE, lwd=1)
	#} else if(walls_total == 6) {
	#	plot(inters, col="lightblue", add=TRUE, lwd=1)
	#} else if(walls_total == 8) {
	#	plot(inters, col="magenta", add=TRUE, lwd=1)
	#}
	
	return(res)
}

get_buildings <- function(ua) {

	bg_ids <- find(ua, way(tags(k == "building")))
	bg_ids <- find_down(ua, way(bg_ids))
	bg <- subset(ua, ids = bg_ids)
	bg_poly <- as_sp(bg, "polygons")


	return(bg_poly)
}

get_streets <- function(ua) {

	hw_ids <- find(ua, way(tags(k == "highway")))
	hw_ids <- find_down(ua, way(hw_ids))
	hw <- subset(ua, ids = hw_ids)
	hw_lines <- as_sp(hw, "lines")

	return(hw_lines)
}

draw_map <- function(data, leg_name, leg_col, leg_lty, leg_pch) {

	mySignal_levels <- c(1000, -20,-30,-80,-90, -1000)
	mySignal_mapping <- approxfun(mySignal_levels, c(1, 1,1,100,100, 100))
	rbPal <- colorRampPalette(c('green','yellow','red'))
	rssi_col <- rbPal(100)


	axis.x.min <- min(data$rx_X)
	axis.x.max <- max(data$rx_X)
	axis.y.min <- min(data$rx_Y)
	axis.y.max <- max(data$rx_Y)
	axis.x.zero <- median(data$tx_X)
	axis.y.zero <- median(data$tx_Y)

	#cat(axis.x.zero)
	#cat(axis.y.zero)
	#cat(axis.x.min)
	#cat(axis.y.min)
	#cat(axis.x.max)
	#cat(axis.y.max)


	axis.x.ticks <- seq(axis.x.min, axis.x.max, length=10)
	#axis.x.ticks <- seq(axis.x.zero , axis.x.max, by=map_ticks_by)
	axis.y.ticks <- seq(axis.y.min, axis.y.max, length=10)
	#axis.y.ticks <- seq(axis.y.zero, axis.y.max, by=map_ticks_by)
	
	#par(mar=c(0.1, 0.1, 0.1, 0.1))
	done <- myps(paste0("map-dynamic_", campaign), width=wi, height=he*1.5)
	par(mar=c(3.8, 3.8,1.0,1.0))

	if(map_online == F) {
		src <- osmsource_file("map.osm")
	} else {
		src <- osmsource_api()
	}
	#src <- osmsource_file("data/maps/andreas_strasse.osm")
	#bb <- center_bbox(sndT[1], sndT[2], 100, 100)

	# or use median?
	bb <- center_bbox(median(data$payload.gpsinfo.lon), median(data$payload.gpsinfo.lat), map_x, map_y)
	ua <- get_osm(bb, source = src)

	buildings <- get_buildings(ua)
	streets <- get_streets(ua)

	buildings <- spTransform(buildings, CRS("+proj=utm +zone=32N +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
	streets <- spTransform(streets, CRS("+proj=utm +zone=32N +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
	#plot(buildings, col="lightgreen", xlim=c(481600, 481800), ylim=c(5731130, 5731330))
	#plot(buildings, col="lightgreen", xlim=c(481800, 481900), ylim=c(5731350, 5731450))
	plot(buildings, col=buildingColor, xlim=c(axis.x.min-map_spacing_x, axis.x.max+map_spacing_x), ylim=c(axis.y.min-map_spacing_y, axis.y.max+map_spacing_y), border=buildingBorderColor)
	plot(streets, add = TRUE, col = "grey")

	walls <- c()
	matter <- c()

	#mySignal_levels <- c(-20,-30,-80,-90)
	#mySignal_mapping <- approxfun(mySignal_levels, c(1,1,100,100))

	#rbPal <- colorRampPalette(c('green','yellow','red'))
	#signal_log$rssi_color <- rbPal(100)[as.numeric(cut(signal_log$pwr,breaks = 100))]
	#signal_log$rssi_color <- rbPal(100)[(1/(signal_log$pwr/-35))*100]
	#data$rssi_color <- rbPal(100)[mySignal_mapping(data$frame_info.rcv_power)]
	data$rssi_color <- rssi_col[mySignal_mapping(data$frame_info.rcv_power)]

	#for(i in 1:nrow(data)) {
        #
	#	res <- get_walls_matter(data[i,]$rx_X, data[i,]$rx_Y, data[i,]$tx_X, data[i,]$tx_Y, buildings, data[i,]$rssi_color)
	#
	#	walls <- rbind(walls, res[1])
	#	matter <- rbind(matter, res[2])
	#}

	data$walls <- walls
	data$matter <- matter

	#############

	#plot(buildings, add=TRUE)
	#plot(streets, add = TRUE, col = "black")
	box()
	#grid()
	axis(1, at=axis.x.ticks, labels=round(axis.x.ticks-axis.x.zero))
	axis(2, at=axis.y.ticks, labels=round(axis.y.ticks-axis.y.zero), las=2)
	title(xlab="distance to sender in m", line=2.8)
	title(ylab="distance to sender in m", line=2.8)
	#title(main=paste0(exp_name, " ", frequency, " ", run_number))

	# maybe use mean or median
	points(median(data$tx_X), median(data$tx_Y), pch=10)
	#text(median(data$tx_X)+30, median(data$tx_Y)+30, "sender", cex=0.8)

	#points(data$rx_X[1], data$rx_Y[1], pch=4)
	#text(signal_log$rcvX[1]+5, signal_log$rcvY[1]+2, "Receiver (Start)", cex=0.8)

	#points(data$rx_X[nrow(data)], data$rx_Y[nrow(data)], pch=4)
	#text(signal_log$rcvX[nrow(signal_log)]+5, signal_log$rcvY[nrow(signal_log)]-2, "Receiver (End)", cex=0.8)

	#text(data$tx_X[1]-6, data$dtx_Y[2]-10, "receiver trajectory", cex=0.8)
	#arrows(sxy[1]-9, sxy[2]-9, sxy[1]-7, sxy[2]+1, length = 0.07, angle = 20)

	##lines(signal_log$rcvX, signal_log$rcvY, lty="dashed", col="black", lwd=3)
	
	#draw.ellipse(sxy[1]+28, sxy[2]+37, 2, 3, angle = 18, lty="dotted", border="black", lwd=2)
	#arrowLine(data$rx_X, data$rx_Y, N=10, lty="dashed", col="black", lwd=3)

	##text(sxy[1]+36, sxy[2]+37, "point A", cex=0.8)
	##arrows(sxy[1]+30, sxy[2]+37, sxy[1]-7, sxy[2]+1, length = 0.07, angle = 20)

	#points(data$rx_X, data$rx_Y, pch=16, cex=0.4)
	points(data$rx_X, data$rx_Y, pch=data$mypch, cex=0.4, col=data$rssi_color, lwd=1)
	points(data$rx_X, data$rx_Y, lty=data$mylty, cex=0.05, col=data$mycol, pch=20)
	lines(data$rx_X, data$rx_Y, lty=data$mylty, lwd=0.7, col=data$mycol, pch=20)

	#text(aggregate(data$rx_X, by=list(data$expno), FUN=median)$x+(axis.x.max-axis.x.zero)*map_text_exp_x, aggregate(data$rx_Y, by=list(data$expno), FUN=median)$x+(axis.y.max-axis.y.zero)*map_text_exp_y, paste0(round(aggregate(data$real_dist, by=list(data$expno), FUN=median)$x), " m"), cex=0.3, col="blue")

	legend("topleft", paste0("Exp.: ", campaign), bty="n", cex=0.8)
	#legend("bottomright", c("sender"), pch=c(10,4), pt.cex=c(1, 0.4), lwd=c(1,2), lty=c(NA, NA))

	legend("bottomright", leg_name, col=leg_col, lty=leg_lty, bty="n", cex=0.4)

	done()
}


exp_filename <- paste0("results/host_rx/", campaign, "/exp.log")
exp <- read.delim(exp_filename ,sep=",")
#exp <- exp[1,]

if (nrow(exp) == 0) {
	error("no experiments found")
}


#done <- myps2(paste0("rsseye_", campaign), width=wi, height=he*1.5)
#par(mar=c(3.8, 3.8,1.0,1.0))

#plot.new()
#plot.window(xlim=c(-2,maxdist), ylim=c(min_rss, max_rss), xaxs='i', yaxs='i')

data <- data.frame()

mycol <- 1
mylty <- 1
mypch <- 16
leg_col <- c()
leg_lty <- c()
leg_pch <- c()
leg_name <- c()

mySignal_levels <- c(1000, -20,-30,-80,-90, -1000)
mySignal_mapping <- approxfun(mySignal_levels, c(1, 1,1,100,100, 100))
rbPal <- colorRampPalette(c('green','yellow','red'))
rssi_col <- rbPal(100)

for(e in 1:nrow(exp)) {

	expno <- exp[e,1]
	dist <- exp[e,2]

	res <- load_data_realdist(campaign, expno, dist)

	#inc1 <- seq(1,nrow(res), by=1)
	#inc2 <- seq(1,nrow(res), by=1)
	#res$rx_X <- res$rx_X + inc1/1
	#res$rx_Y <- res$rx_Y + inc1/1
	#res$frame_info.rcv_power <- res$frame_info.rcv_power - inc2/20
	
	if(nrow(res) > 0) {

		res$mycol <- mycol
		res$mylty <- mylty
		res$mypch <- mypch

		res$rssi_color <- rssi_col[mySignal_mapping(res$frame_info.rcv_power)]

		data <- rbind(data, res)

		leg_col <- c(leg_col, mycol)
		leg_lty <- c(leg_lty, mylty)
		leg_pch <- c(leg_pch, mypch)
		leg_name <- c(leg_name, paste0("expno: ", expno, "; dist/angle: ", mean(res$dist)))
		mycol <- mycol + 1
		#mylty <- mylty + 1
		#mypch <- mypch + 1
		
	}
}

draw_map(data, leg_name, leg_col, leg_lty, leg_pch)

#legend("bottomleft", paste0("Exp.: ", campaign), bty="n", cex=0.8)

#axis(1)
#axis(2, las=2)
#title(xlab="distance in m", line=2.8)
#title(ylab="received signal strength in dBm", line=2.8)
#box()

#done()



