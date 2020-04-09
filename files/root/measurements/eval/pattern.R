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

buildingCololor <- "white"
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

load_data <- function (campaign, expno, dist) {

	rx_filename <- paste0("results/host_rx/", campaign, "/", expno, "/rsseye/rsseye_rx_expno-",expno,"_dist-",dist,".csv")

	rx <- read.delim(rx_filename ,sep=",")

	data <- subset(rx, !is.na(frame_info.rcv_power))

	if(nrow(data) == 0) {
		return(data.frame())
	}
	
	data$campaign <- campaign
	data$expno <- expno
	data$dist <- dist

	data$mydist <- data$dist

	return(data)
}


require('ggplot2')
require(plotrix)
require(RColorBrewer)

#palette( hcl(h=seq(0, 360, length.out=4), c=55, l=55))
#palette(rainbow(4))
palette(brewer.pal(n=4, name="PuOr"))

plotAntennaPattern <- function(vecData, outputFile, legend) {

	#pdf(file=outputFile, height=6, width=5)
	done <- myps2(outputFile, width=wi, height=he*1.5)
	par(mar=c(3.8, 3.8,1.0,1.0))
	par(cex.lab=0.4)
	par(cex.axis=0.5)

	radial.lims = c(-130,-10)

	polar.plot(0, rp.type="p", label.pos=c(seq(0, 330, by=30)), labels=c(seq(0, 330, by=30)), radial.lim=radial.lims, mar=c(3, 0.5, 0.5, 0.5))

	#poly1_x <- c(-20, 20, 20, -20)
	#poly1_y <- c(15, 15, -15, -15)
	#polygon(poly1_x, poly1_y, col="black")

	#poly2_x <- c(10, 30, 30, 10)
	#poly2_y <- c(5, 5, -5, -5)
	#polygon(poly2_x, poly2_y, col="black")
	#text(20, 0, "Front", col="white", cex=0.5)

	poly1_x <- c(-15, -20, 20, 20, -20, -15)
	poly1_y <- c(0, 15, 0, 0, -15, 0)
	polygon(poly1_x, poly1_y, col="black")


	#cat("length:", length(vecData))

	for (ant in 1:length(vecData)) {

		ant1 <- vecData[[ant]]

		#if (csvFiles[ant] == 'ant1_ok.csv') {
		#	powers <- ant1$RXPWB
		#}
		#else {
		#	powers <- ant1$RxPWA
		#}

		p1a1 <- data.frame(pod="Pod 1",ant="Ant 1",angle=ant1$dist,pw=ant1$frame_info.rcv_power)

		ds <- p1a1
		ds.a <- aggregate(ds$pw, by=list(pod=ds$pod, ant=ds$ant, angle=ds$angle), FUN=mean)
		ds.stddev <- aggregate(ds$pw, by=list(pod=ds$pod, ant=ds$ant, angle=ds$angle), FUN=sd)
	
		if (max(ds.a$angle) != 355) {
#			missing <- seq(max(ds.a$angle) + 5, 355, by=5)
#			df <- data.frame(angle=missing, x=rep(NA, length(missing)), pod=rep('Pod 1', length(missing)), ant=rep('Ant 1', length(missing)))
#			ds.a <- rbind(ds.a, df)
#			print(ds.a)
			ds.a <- rbind(ds.a, ds.a[order(ds.a$angle, decreasing=T),])
			#print(ds.a)
		}

		if (length(vecData) == 2) {
			leg.col <- c(1,3)
			if (ant == 1) {
				color <- 1
			}
			else {
				color <- 3
			}
		}
		else {
			leg.col <- c(1:length(vecData))
			color <- ant
		}

		p <- polar.plot(ds.a$x, polar.pos=ds.a$angle, line.col=color, lwd=3, add=T, rp.type="p",  radial.lim=radial.lims)


	}

	legend(
		x="topleft",
		legend=legend,
		col=leg.col, 
		lwd=3,
		bty="n",
#		horiz=T,
		ncol=2,
		inset=c(0,1.05),
#		pch=c(c(""), pch1),
#		lwd=c(3,1,1)
		cex=0.8
	)
	#dev.off()
	done()

}



exp_filename <- paste0("results/host_rx/", campaign, "/exp.log")
exp <- read.delim(exp_filename ,sep=",")

if (nrow(exp) == 0) {
	error("no experiments found")
}

data <- data.frame()

for(e in 1:nrow(exp)) {

	expno <- exp[e,1]
	dist <- exp[e,2]

	if(use_realdist==T) {
		res <- load_data_realdist(campaign, expno, dist)
	} else {
		res <- load_data(campaign, expno, dist)
	}
	
	if(nrow(res) > 0) {

		data <- rbind(data, res)
	}
}


#plotAntennaPattern(c('ant1.csv', 'ant2.csv'), 'antenna_pattern.pdf', legend=c('MGW-303/GPS 1', 'MGW-303/GPS 2'))
plotAntennaPattern(list(data), paste0("pattern_", campaign), legend=c(campaign))
