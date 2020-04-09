#include <ctype.h>
#include <getopt.h>
#include <gps.h>
#include <math.h>

#include "transceiver.h"

#define BILLION  1000000000L


typedef struct __attribute__ ((__packed__)) {
	double systime;
	double gpstime;
	double lon;
	double lat;
	uint8_t satellites;
	uint8_t mode;
	uint8_t status;
} gpsinfo_t;


typedef struct __attribute__ ((__packed__)) {
	uint32_t id;
	uint32_t seqno;
	uint32_t totalno;
	uint32_t intvlms;
	uint32_t rateidx;
	uint32_t bw;
	uint32_t expno;
	double systime;
	gpsinfo_t gpsinfo;
} payload_t;


// last GPS fix received
gpsinfo_t gpsinfo;
pthread_mutex_t gpsinfo_mutex = PTHREAD_MUTEX_INITIALIZER;


// used to mark our packets
const uint32_t RSSEYE_ID = 0xAAA55E1E;


// set to 0 when program is supposed exit
int run = 1;

int gps_fix = STATUS_NO_FIX;


// program parameters
int do_send = 0;
int do_receive = 0;
char* log_fname = 0;
int time_ms = 200;
int rateIndex = 5;
int totalno = 0;
int bw = 10;
int expno = 0;
char* interfName = "wlan0";
int quiet = 0;


void stop_signal_handler(int sig) {
	// unlock only infinite loop
	run = 0;
}


// --- gps --------------------------------------------------------------------
void* gps_thread(void* params) {
	struct gps_data_t gpsdata;

	// open GPS
	if (gps_open("localhost", "2947", &gpsdata)<0) {
		fprintf(stderr,"Could not connect to GPSd\n");
		return 0;
	}

	// start streaming
	gps_stream(&gpsdata, WATCH_ENABLE | WATCH_JSON, NULL);

	// whenever new data is available, store it to `gpsinfo'
	double lastTime = NAN;
	while (run) {
		while (run) {
			if (!gps_waiting(&gpsdata, 1 * 1000 * 1000)) {
				gps_fix = STATUS_NO_FIX;
				continue;
			}
			if (gps_read(&gpsdata)==-1) {
				fprintf(stderr,"GPSd Error\n");
				gps_fix = STATUS_NO_FIX;
				break;
			}
			if (gpsdata.set && gpsdata.status > STATUS_NO_FIX) {
				gps_fix = gpsdata.status;
				break;
			}
		}
		if (!run) break;
		if (gpsdata.fix.time != gpsdata.fix.time) {
			gps_fix = STATUS_NO_FIX;
			continue;
		}
		if (gpsdata.fix.time == lastTime) {
			gps_fix = STATUS_NO_FIX;
			continue;
		}
		lastTime = gpsdata.fix.time;

		// get current time
		struct timespec systime_ts;
		clock_gettime( CLOCK_REALTIME, &systime_ts);
		double systime = systime_ts.tv_sec + systime_ts.tv_nsec/(double)BILLION;

		if (pthread_mutex_lock(&gpsinfo_mutex) != 0) perror("pthread_mutex_lock");
		gpsinfo.systime = systime;
		gpsinfo.gpstime = gpsdata.fix.time;
		gpsinfo.lon = gpsdata.fix.longitude;
		gpsinfo.lat = gpsdata.fix.latitude;
		gpsinfo.satellites = gpsdata.satellites_visible;
		gpsinfo.mode = gpsdata.fix.mode;
		gpsinfo.status = gpsdata.status;
		if (pthread_mutex_unlock(&gpsinfo_mutex) != 0) perror("pthread_mutex_unlock");
	}

	// stop streaming
	gps_stream(&gpsdata, WATCH_DISABLE, NULL);

	// close GPS
	gps_close(&gpsdata);

	return 0;
}


// --- send -------------------------------------------------------------------
void* send_thread(void* params) {
	device_t* device = (device_t*)params;
	int seqno = 0;
	payload_t payload;


	while (run && ((seqno < totalno) || totalno==0)) {
		// sleep
		struct timespec time[1];
		time[0].tv_sec = 0;
		time[0].tv_nsec = (time_ms * 1000* 1000); // 200 ms
		nanosleep(time, NULL);

		// get current time
		struct timespec systime_ts;
		clock_gettime( CLOCK_REALTIME, &systime_ts);
		double systime = systime_ts.tv_sec + systime_ts.tv_nsec/(double)BILLION;

		// prepare packet
		payload.id = RSSEYE_ID;
		payload.seqno = seqno;
		payload.totalno = totalno;
		payload.intvlms = time_ms;
		payload.rateidx = rateIndex;
		payload.bw = bw;
		payload.expno = expno;
		payload.systime = systime;
		if (pthread_mutex_lock(&gpsinfo_mutex) != 0) perror("pthread_mutex_lock");
		payload.gpsinfo = gpsinfo;
		if (pthread_mutex_unlock(&gpsinfo_mutex) != 0) perror("pthread_mutex_unlock");

		if(isnan(payload.gpsinfo.lat) || isnan(payload.gpsinfo.lon)) {
			if(!quiet) {fprintf(stderr, "WARNING: we will send a packet, but we do not have lat/lon information!\n");
			fflush(stderr);}
		}

		// send
		if(!quiet) fprintf(stderr, "sending packet...\n");
		send_frame(device, &payload, sizeof(payload_t), 64000, rateIndex);

		// increase sequence number
		seqno++;

		if(totalno>0 && (seqno == (totalno))) { // last packet sent
			run=0;
			if (!quiet) {fprintf(stderr, "last packet sent, quitting...\n");
			fflush(stderr);}
		}
	}

	return 0;
}

// --- receive ----------------------------------------------------------------
void* receive_thread(void* params) {
	device_t* device = (device_t*)params;

	payload_t payload;
	struct frame_info_t frame_info;

	char csv_str[] = "payload.seqno,"
			 "payload.totalno,"
			 "payload.intvlms,"
			 "payload.rateidx,"
			 "payload.bw,"
			 "payload.expno,"
			 "payload.systime,"
			 "payload.gpsinfo.systime,"
			 "payload.gpsinfo.gpstime,"
			 "payload.gpsinfo.lon,"
			 "payload.gpsinfo.lat,"
			 "payload.gpsinfo.satellites,"
			 "payload.gpsinfo.mode,"

			 "systime,"
			 "rcv_gpsinfo.systime,"
			 "rcv_gpsinfo.gpstime,"
			 "rcv_gpsinfo.lon,"
			 "rcv_gpsinfo.lat,"
			 "rcv_gpsinfo.satellites,"
			 "rcv_gpsinfo.mode,"

			 "frame_info.noise_power,"
			 "frame_info.rcv_power"

			 "\n";

	printf(csv_str);

	while (run) {
		int n;
		memset(&payload, 0, sizeof(payload_t));
		n = receive_frame(device, &payload, sizeof(payload_t), &frame_info, 1);

		// get current time
		struct timespec systime_ts;
		clock_gettime( CLOCK_REALTIME, &systime_ts);
		double systime = systime_ts.tv_sec + systime_ts.tv_nsec/(double)BILLION;

		// get current gps info
		if (pthread_mutex_lock(&gpsinfo_mutex) != 0) perror("pthread_mutex_lock");
		gpsinfo_t rcv_gpsinfo = gpsinfo;
		if (pthread_mutex_unlock(&gpsinfo_mutex) != 0) perror("pthread_mutex_unlock");

		if (n < 0) {
			fprintf(stderr, "error receiving\n");
			continue;
		}
		if (n == 0) {
			continue;
		}
		if (frame_info.was_tx) {
			continue;
		}
		if (payload.id != RSSEYE_ID) {
			fprintf(stderr, "received frame was not an RSSEYE frame. Ignoring.\n");
			continue;
		}

		char fmt_str[] = ""
			"%" PRIu32 ","
			"%" PRIu32 ","
			"%" PRIu32 ","
			"%" PRIu32 ","
			"%" PRIu32 ","
			"%" PRIu32 ","

			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%" PRIu8 ","
			"%" PRIu8 ","

			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%17.12f,"
			"%" PRIu8 ","
			"%" PRIu8 ","

			"%f,"
			"%f"

			"\n";

		printf(fmt_str,
				payload.seqno,
				payload.totalno,
				payload.intvlms,
				payload.rateidx,
				payload.bw,
				payload.expno,

				payload.systime,
				payload.gpsinfo.systime,
				payload.gpsinfo.gpstime,
				payload.gpsinfo.lon,
				payload.gpsinfo.lat,
				payload.gpsinfo.satellites,
				payload.gpsinfo.mode,

				systime,
				rcv_gpsinfo.systime,
				rcv_gpsinfo.gpstime,
				rcv_gpsinfo.lon,
				rcv_gpsinfo.lat,
				rcv_gpsinfo.satellites,
				rcv_gpsinfo.mode,

				frame_info.noise_power,
				frame_info.rcv_power
					);

		fflush(stdout);

		if(isnan(payload.gpsinfo.lat) || isnan(payload.gpsinfo.lon) || isnan(rcv_gpsinfo.lat) || isnan(rcv_gpsinfo.lon)) {
			fprintf(stderr, "WARNING: received a packet, but we do not have lat/lon information!\n");
			fflush(stderr);
		}

		if(payload.totalno>0 && (payload.seqno == (payload.totalno-1))) { // last packet received
			run=0;
			if(!quiet) {fprintf(stderr, "last packet received, quitting...\n");
			fflush(stderr);}
		}

	}

	return 0;
}


int main (int argc, char* argv[]) {
	// handle all kinds of signals
	//signal(SIGTERM, &stop_signal_handler);
	//signal(SIGINT, &stop_signal_handler);
	//signal(SIGABRT, &stop_signal_handler);

	// init variables
	memset(&gpsinfo, 0, sizeof(gpsinfo_t));
	gpsinfo.lat = NAN;
	gpsinfo.lon = NAN;

	// parse command line options
	{
		opterr = 0;
		int c;
		while ((c = getopt (argc, argv, "hsrl:t:m:a:e:b:i:q:")) != -1) {
			switch (c) {
				case 'h':
					fprintf(stderr, "-h -- show help\n-s -- start sender\n-r -- start receiver\n-l -- log to file\n-t -- interval in ms between packets (default 200ms)\n-m -- data rate index: 0 = 54, 1 = 48, 2 = 36, 3 = 24, 4 = 18, 5 = 12, 6 = 9, 7 = 6; (in MBit/s); holds for 20 MHz channels, half/quarter for 10/5 MHz channels; default = 5\n-a how many packets to send, 0 for infinite (default)\n-e experiment number (to be logged in csv, default 0)\n-b channel bandwidth (does NOT SET bandwidth, just to be logged in csv, needs to be set using iw, default 10)\n-i interface name\n-q 1 to be quiet\n");
					exit(0);
					break;
				case 's':
					do_send = 1;
					break;
				case 'r':
					do_receive = 1;
					break;
				case 'l':
					log_fname = optarg;
					break;
				case 't':
					time_ms = atoi(optarg);
					break;
				case 'm':
					rateIndex = atoi(optarg);
					break;
				case 'a':
					totalno = atoi(optarg);
					break;
				case 'e':
					expno = atoi(optarg);
					break;
				case 'b':
					bw = atoi(optarg);
					break;
				case 'i':
					interfName = optarg;
					break;
				case 'q':
					quiet = atoi(optarg);
					break;
				case '?':
					if (optopt == 'l') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 't') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'm') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'a') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'e') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'b') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'i') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (optopt == 'q') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					} else if (isprint (optopt)) {
						fprintf(stderr, "Unknown option `-%c'.\n", optopt);
					} else {
						fprintf(stderr, "Unknown option character `\\x%x'.\n", optopt);
					}
					return 1;
				default:
					abort ();
			}
		}
		int index;
		for (index = optind; index < argc; index++) {
			fprintf(stderr, "Non-option argument %s\n", argv[index]);
			return 1;
		}
	}

	// open NIC
	tTxOpts tx_options;
	tMyMACAddress src_mac = { 0x04, 0xe5, 0x48, 0x00, 0x10, 0x00 };
	tMyMACAddress dst_mac = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
	tx_options.ChannelOptions.ChannelNumber = 178;
	tx_options.ChannelOptions.Priority = _PRIO_0;
	tx_options.ChannelOptions.Service = _QOS_NOACK;
	tx_options.ChannelOptions.pModulationCodingScheme = ModulationCodingScheme_R12BPSK;
	tx_options.ChannelOptions.TxPower = 20; // useless, needs to set using iw or force_tx power debugfs entry
	tx_options.ChannelOptions.pTxAntenna = _TXANT_DEFAULT;
	tx_options.ChannelOptions.Bandwidth = BW_10MHz;
	memcpy(tx_options.ChannelOptions.DestAddr, dst_mac, sizeof tx_options.ChannelOptions.DestAddr);
	tx_options.ChannelOptions.EtherType = 0x88b5;
	memcpy(tx_options.SrcAddr, src_mac, sizeof tx_options.SrcAddr);
	tx_options.pInterfaceName = interfName;
	init_setup(&tx_options);
	device_t* device = (device_t*)open_device(&tx_options);

	// start threads
	pthread_t gps_thread_id;
	pthread_t send_thread_id;
	pthread_t receive_thread_id;
	pthread_create(&gps_thread_id, NULL, gps_thread, (void*)device);

	if (do_send) {
		// sleep
		struct timespec time[1];
		time[0].tv_sec = 0;
		time[0].tv_nsec = (2000 * 1000* 1000); // 2000 ms to get information from gps
		nanosleep(time, NULL);
		pthread_create(&send_thread_id, NULL, send_thread, (void*)device);
	}
	if (do_receive) {
		pthread_create(&receive_thread_id, NULL, receive_thread, (void*)device);
	}

	// now wait for the threads to finish
	if (do_receive) {
		pthread_join(receive_thread_id, NULL);
	}
	if (do_send) {
		pthread_join(send_thread_id, NULL);
	}
	//pthread_join(gps_thread_id, NULL);

	// close up
	close_device(device);

	// ...and we're done
	return 0;
}

