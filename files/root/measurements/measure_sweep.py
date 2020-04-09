import subprocess
import time
import threading
import os
import csv
import argparse
import signal
import traceback
import json
import gpsd

class DataThread(threading.Thread): 
    def __init__(self, interface, output): 
        threading.Thread.__init__(self) 
        self.interface = interface
        self.output = output
        self.finished = False
        gpsd.connect()
 
    def run(self): 
#        tmp_file = "/tmp/sweep_dump_last_lines.json"
#        if os.path.exists(tmp_file):
#            with open(tmp_file) as tmp:
#                last_lines = set(json.load(tmp))
#        else:
        last_lines = set()
        try:
            
            sweep_dump_file = "/sys/kernel/debug/ieee80211/{}/wil6210/sweep_dump".format(self.interface)
            with open(self.output, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile, delimiter=';')
                writer.writerow(["num", "src", "sec", "cdown", "dir", "snr_db", "gps_time", "gps_lon", "gps_lat"])
                first = True
                while not self.finished:
                    packet = gpsd.get_current()
                    new_lines = set()
                    found = False
                    #print(last_lines)
                    with open(sweep_dump_file) as tmp:
                        
                        for line in tmp.read().splitlines():
                            if line[0:2] == " [":
                                new_lines.add(line)
                                if line in last_lines or first:
                                    continue
                                
                                line = line[line.index("[")+1:line.rindex("]")].strip()
                                while "  " in line:
                                    line = line.replace("  "," ")
                                line_s = line.split(" ")
                                num = line_s[0]
                                src = line_s[2]
                                sec = line_s[4]
                                cdown = line_s[6]
                                dir = line_s[8]
                                snr_db = line_s[10]
                                writer.writerow([num, src, sec, cdown, dir, snr_db, packet.time, packet.lon, packet.lat])
                                found = True
#                    if found:
#                        print("New data")
                    last_lines = new_lines
                    time.sleep(0.1)
                    first = False
        except:
            print("Err")
            traceback.print_exc()
#        with open(tmp_file, "w") as tmp:
#            json.dump(list(last_lines), tmp)
    def stop(self):
        self.finished = True
        


parser = argparse.ArgumentParser(description='Parses the values of sweep_dump and write them to a csv file')

parser.add_argument( '--output', '-o',
                    help='File to write to', required=True)

parser.add_argument( '--interface', '-i',
                    help='Interface to measure (default: phy2)',default='phy2')

parser.add_argument( '--time', '-t',
                    help='Time in seconds for measurements (default: unlimited)', type=int)


parser.add_argument( '--receiver', '-r',
                    help='Receiver for ping (default: no ping)')

args = parser.parse_args()

    


dT = DataThread(args.interface, args.output)


def exit_gracefully(signum, frame):
    dT.stop()

signal.signal(signal.SIGINT, exit_gracefully)
signal.signal(signal.SIGTERM, exit_gracefully)


if args.time:
    def exit_after_n_seconds(seconds):
        time.sleep(seconds)
        dT.stop()
    t = threading.Thread(target=exit_after_n_seconds, args=(args.time,))
    t.start()
    
    
    


    
if args.receiver:
    process = subprocess.Popen(["ping", "-f", args.receiver])
dT.start()
while not dT.finished:
    dT.join(timeout=0.1)
if args.receiver:
    process.kill()


print ("Finished measurement")

