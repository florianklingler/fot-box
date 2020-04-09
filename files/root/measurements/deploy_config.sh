#!/bin/bash

rsync -Ppax _settings.sh root@10.0.197.104:/root/measurements/
rsync -Ppax _settings.sh root@10.0.197.105:/root/measurements/

rsync -Ppax _setup_interface_ocb_mon.sh root@10.0.197.104:/root/measurements/
rsync -Ppax _setup_interface_ocb_mon.sh root@10.0.197.105:/root/measurements/

rsync -Ppax do_measurements_tx.sh root@10.0.197.104:/root/measurements/
rsync -Ppax do_measurements_tx.sh root@10.0.197.105:/root/measurements/

rsync -Ppax do_measurements.sh root@10.0.197.104:/root/measurements/
rsync -Ppax do_measurements.sh root@10.0.197.105:/root/measurements/

#rsync -Ppax ../.ssh/config root@10.0.197.104:/root/.ssh/
#rsync -Ppax ../.ssh/config root@10.0.197.105:/root/.ssh/
