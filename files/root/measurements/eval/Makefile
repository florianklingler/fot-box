joined_%.pdf: map_%.pdf rsseye_%.pdf pdr_rsseye_%.pdf sockperf_tcp_%.pdf sockperf_udp_%.pdf iperf_tcp_%.pdf iperf_udp_%.pdf
	pdfjoin --outfile joined_$*.pdf map_$*.pdf rsseye_$*.pdf pdr_rsseye_$*.pdf sockperf_tcp_$*.pdf sockperf_udp_$*.pdf iperf_tcp_$*.pdf iperf_udp_$*.pdf
	#evince joined_$*.pdf &

joined2_%.pdf: map_%.pdf pattern_%.pdf
	pdfjoin --outfile joined2_$*.pdf map_$*.pdf pattern_$*.pdf
	#evince joined2_$*.pdf &

joined3_%.pdf: map-dynamic_%.pdf rsseye-dynamic-index_%.pdf rsseye-dynamic-dist_%.pdf
	pdfjoin --outfile joined3_$*.pdf map-dynamic_$*.pdf rsseye-dynamic-index_$*.pdf rsseye-dynamic-dist_$*.pdf
	#evince joined3_$*.pdf &

map_%.pdf: map.R _settings.R
	Rscript $< $*

map-dynamic_%.pdf: map-dynamic.R _settings.R
	Rscript $< $*

rsseye_%.pdf: rsseye.R _settings.R
	Rscript $< $*

rsseye-dynamic-index_%.pdf: rsseye-dynamic.R _settings.R
	Rscript $< $* index

rsseye-dynamic-dist_%.pdf: rsseye-dynamic.R _settings.R
	Rscript $< $* dist

pdr_rsseye_%.pdf: pdr_rsseye.R _settings.R
	Rscript $< $*

sockperf_tcp_%.pdf: sockperf.R _settings.R
	Rscript $< $* tcp

sockperf_udp_%.pdf: sockperf.R _settings.R
	Rscript $< $* udp

iperf_tcp_%.pdf: iperf.R _settings.R
	Rscript $< $* tcp

iperf_udp_%.pdf: iperf.R _settings.R
	Rscript $< $* udp

pattern_%.pdf: pattern.R _settings.R
	Rscript $< $*

