// gpslogger.c - log GPS data to file


#include <sys/types.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <stdint.h>

#include <time.h>
#include <math.h>
#include <limits.h>
#include <signal.h>
#define OPTION_LEN 4
#define BILLION  1000000000L


#include <gps.h>

static struct gps_data_t gpsdata;
static FILE* out_file;


struct input_opt {
	unsigned int verbose;
	char output_file_name[255];
	unsigned int do_sync;
};

void debug_print(char* s) {
	struct timespec t0;
	clock_gettime( CLOCK_REALTIME, &t0);
	double system_time = t0.tv_sec + t0.tv_nsec/(double)BILLION;

	fprintf(stderr, "%.12f %s\n", system_time, s);
}

void init_input_opt(struct input_opt* opt) {
	opt->verbose=0;
	sprintf(opt->output_file_name,"%s","");
	opt->do_sync=0;
}
void my_handler(int s) {
	fprintf(stderr,"\nCaught signal %d\n",s);
	exit(1);
}

static void say_goodbye() {
	debug_print("exiting");
}

static void close_gps() {
	fprintf(stderr,"Closing GPS\n");
	gps_close(&gpsdata);
}

static void stop_streaming() {
	gps_stream(&gpsdata, WATCH_DISABLE, NULL);
}

static void close_file() {
	fclose(out_file);
}

void usage(int argc,char* argv[], struct option long_options [],char* desc[]) {

	int i=0;
	fprintf(stdout,"usage %s:\n",argv[0]);
	for (i=0; i<OPTION_LEN-1; i++) {
		struct option l_opt=long_options[i];
		fprintf(stdout,"-%c  \t --%-10s  %s\n",(char)l_opt.val,l_opt.name,desc[i]);
	}

}
int get_opt_list(struct option long_options[], char* char_ret) {
	int ret=0;
	int i=0;
	for (i=0; i<OPTION_LEN; i++) {
		struct option lopt = long_options[i];
		if (lopt.has_arg)
			sprintf(char_ret,"%s%c:",char_ret,(char)(lopt.val));
		else
			sprintf(char_ret,"%s%c",char_ret,(char)(lopt.val));
	}
	sprintf(char_ret,"%s\0",char_ret);
	return ret;
}

int parseargs(int argc, char* argv[], struct input_opt* myopt, struct option long_options[], char* desc[]) {
	if (argc == 1)
		return -1;
	int c;
	int option_index = 0;

	char opt_list[100]="";
	get_opt_list(long_options,opt_list);

	while ((c = (signed char)getopt_long(argc, argv, opt_list,long_options, &option_index)) != EOF) {

		switch (c) {
			case 'e':
				sprintf(myopt->output_file_name,"%s",optarg);
				break;
			case 'v':
				myopt->verbose=1;
				break;
			case 's':
				myopt->do_sync=1;
				break;
			case 'h':
				usage(argc,argv,long_options,desc);
				exit(0);
				break;

			default:
				usage(argc,argv,long_options,desc);
				exit(0);
				break;
		}
	}
	return 0;
}

void setTimeFromGPS(double gps_time) {
	char command[512]="";
	sprintf(command,"date +%%s.%%N -s @\"%f\"",gps_time);
	//printf("%s\n",command);
	system(command);
}

int getGPSData2(struct gps_data_t* gpsdata) {
	while (1) {
		if (!gps_waiting(gpsdata, 1 * 1000 * 1000)) {
			continue;
		}
		if (gps_read(gpsdata)==-1) {
			fprintf(stderr,"GPSd Error\n");
			return(-1);
		}
		if (gpsdata->set && gpsdata->status > STATUS_NO_FIX) {
			break;
		}
	}
	return 0;
}

void gpsdataToString(struct gps_data_t* gpsdata,char* output_dump) {
	sprintf(output_dump,"%17.12f,%17.12f,%17.12f,%17.12f,%23.12f,%23.12f,%3u\n", gpsdata->fix.latitude, gpsdata->fix.longitude, gpsdata->fix.altitude, (gpsdata->fix.epx>gpsdata->fix.epy)?gpsdata->fix.epx:gpsdata->fix.epy, gpsdata->fix.time, gpsdata->online, gpsdata->satellites_visible);
}

int main(int argc, char* argv[]) {
	atexit(say_goodbye);
	debug_print("starting");


	struct sigaction sigIntHandler;

	sigIntHandler.sa_handler = my_handler;
	sigemptyset(&sigIntHandler.sa_mask);
	sigIntHandler.sa_flags = 0;

	sigaction(SIGINT, &sigIntHandler, NULL);
	sigaction(SIGTERM, &sigIntHandler, NULL);





	static char* desc[]= {
		"verbose mode",
		"export log to file",
		"wait for time and synchronize local clock",
		"print this help",
		""
	};
	static struct option long_options[] = {
		{"verbose",	no_argument,		0, 'v'},
		{"export",	required_argument,	0, 'e'},
		{"sync", 	no_argument, 		0, 's'},
		{"help", 	no_argument, 		0, 'h'},
		{0, 		0, 			0, 0}
	};
	struct input_opt myopt;

	init_input_opt(&myopt);
	parseargs(argc,argv,&myopt,long_options,desc);

	if (gps_open("localhost", "2947", &gpsdata)<0) {
		fprintf(stderr,"Could not connect to GPSd\n");
		exit(1);
	}
	atexit(close_gps);
	gps_stream(&gpsdata, WATCH_ENABLE | WATCH_JSON, NULL);
	atexit(stop_streaming);

	if (myopt.do_sync) {
		fprintf(stdout,"waiting for time from GPS...\n");
		while (1) {
			getGPSData2(&gpsdata);

			if (gpsdata.fix.time == gpsdata.fix.time) break;

		}
		fprintf(stdout,"setting local time to %23.12f\n", gpsdata.fix.time);
		setTimeFromGPS(gpsdata.fix.time);
	}

	// exit if neither -e nor -v was given
	if (!strcmp(myopt.output_file_name,"") && !myopt.verbose) {
		exit(0);
	}

	char gps_dump_msg[1024];
	sprintf(gps_dump_msg,"%17s,%17s,%17s,%17s,%23s,%23s,%3s\n","Lat","Lon","Alt","Accuracy","Time","Online","Sat");

	if (strcmp(myopt.output_file_name,"")) {
		out_file = fopen(myopt.output_file_name, "w");
		atexit(close_file);
		fprintf(out_file,"%s",gps_dump_msg);
		fflush(out_file);
	}


	if (myopt.verbose) {
		fprintf(stdout,"%s",gps_dump_msg);
	}


	double lastTime = NAN;
	while (1) {
		if (getGPSData2(&gpsdata) != 0) {
			continue;
		}
		if (gpsdata.fix.time != gpsdata.fix.time) {
			continue;
		}
		if (gpsdata.fix.time == lastTime) {
			continue;
		}
		lastTime = gpsdata.fix.time;

		if (strcmp(myopt.output_file_name,"")) {
			gpsdataToString(&gpsdata,gps_dump_msg);
			fprintf(out_file,"%s",gps_dump_msg);
			fflush(out_file);
		}

		if (myopt.verbose) {
			gpsdataToString(&gpsdata,gps_dump_msg);
			fprintf(stdout,"%s",gps_dump_msg);
		}

	}

	// we should never get here
	return 0;
}


