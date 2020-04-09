#!/bin/bash

source _settings.sh
if [ $# -ne 1 ]; then ssh-add /root/.ssh/${ssh_priv_key_file}; fi

killall ssh
udhcpc -i $internet_interface
if [ ${use_autossh} -eq 1 ]; then
	echo "using autossh"
	export AUTOSSH_POLL=5
	export AUTOSSH_LOGFILE=/tmp/autossh.log
	autossh -M 10250 -f -N setup-measurements-rx
else
	echo "using normal ssh"
	ssh -N -f setup-measurements-rx
fi
