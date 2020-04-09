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


exp_filename <- paste0("results/host_rx/", campaign, "/exp.log")
exp <- read.delim(exp_filename ,sep=",")

if (nrow(exp) == 0) {
	error("no experiments found")
}


done <- myps2(paste0("rsseye_", campaign), width=wi, height=he*1.5)
par(mar=c(3.8, 3.8,1.0,1.0))

plot.new()
plot.window(xlim=c(-2,maxdist), ylim=c(min_rss, max_rss), xaxs='i', yaxs='i')

v.x = c()
v.q1 = c()
v.q2 = c()
v.q3 = c()
v.out.x = c()
v.out.y = c()

for(e in 1:nrow(exp)) {

	expno <- exp[e,1]
	dist <- exp[e,2]

	if(use_realdist==T) {
		res <- load_data_realdist(campaign, expno, dist)
	} else {
		res <- load_data(campaign, expno, dist)	
	}
	
	if(nrow(res) > 0) {
		b <- boxplot(at=mean(res$mydist), res$frame_info.rcv_power, add=T, axes=FALSE, pars = list(boxwex = 35, staplewex = 0.5, outwex = 1.0, outpch=4, outcex=0.3, outcol=rgb(0,0,0, .1)), plot=draw_boxplots)

		mean.x = mean(res$mydist)

		v.x = c(v.x, mean.x)
		v.q1 = c(v.q1, b$stats[2,])
		v.q2 = c(v.q2, b$stats[3,])
		v.q3 = c(v.q3, b$stats[4,])
		v.out.x = c(v.out.x, rep(mean.x, length(b$out)))
		v.out.y = c(v.out.y, b$out)

		#points(dist, mean(res$frame_info.rcv_power))

		#text( mean(res$dist), b$stats[nrow(b$stats) , ]+0.5 , paste("n = ",mean(res$real_dist),sep=""), cex=0.3)
	}
}

#v.out.x = v.out.x + runif(length(v.out.x), min=-.01*maxdist, max=.01*maxdist)

if(draw_boxplots==F) {
	points(v.out.x, v.out.y, pch=4, cex=0.3, col=rgb(0,0,0, .1))
	lines(v.x, v.q1, lwd=1, col="grey")
	lines(v.x, v.q3, lwd=1, col="grey")
	#polygon(c(v.x, rev(v.x)), c(v.q1, rev(v.q3)), col=rgb(.6, .6, .6, .6), border=NA)
	polygon(c(v.x, rev(v.x)), c(v.q1, rev(v.q3)), col="grey", border=NA)
	points(v.x, v.q2, pch=16, cex=.4)
	lines(v.x, v.q2, lwd=2, col="black")

}

legend("bottomleft", paste0("Exp.: ", campaign), bty="n", cex=0.8)

axis(1)
axis(2, las=2)
title(xlab="distance in m", line=2.8)
title(ylab="received signal strength in dBm", line=2.8)
box()

done()


















