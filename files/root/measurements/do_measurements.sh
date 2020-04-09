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

#!/bin/bash

#stty -echoctl
reset

source _settings.sh
measurements_dynamic=0

if [ $# != 1 ]; then
	echo "missing arguments: <Measurement-Campaign-Name>"
	read -e -p "Campaign Name: " campaign
	#exit 1
else
	campaign=$1
fi

if [ -d "${resultsdir}/${campaign}" ]; then
  echo "results for campaign '${campaign}' already exist. Check name!"
  exit 1
fi

echo "Enter 1 to do dynamic measurements"
read -e -p "Dynamic: " -i "${measurements_dynamic}" measurements_dynamic

if [ ${measurements_dynamic} == 1 ]; then
	echo "Doing Dynamic Measurement Campaign"
else
	echo "Doing Static Measurement Campaign"
	measurements_dynamic=0
fi


# $1: result var (pid)
# $2: ip/hostname of remote SSH server
# returns: 0 if connection OK, 1 otherwise
function _setup_ssh_master {

	local ssh_command="ssh -N -n -f root@$2"

	local __resultvar=$1
	${ssh_command}
	local retval=$? # exit code of ssh process

	if [ $retval -ne 0 ]; then
		echo "error: setup ssh master"
		return 1
	fi

	local mypid=$(pgrep -f "${ssh_command}")

	if [ $mypid == "" ]; then
		echo "error: get pid of ssh master"
		return 1
	fi

	local myresult=$mypid
	eval $__resultvar="'$myresult'"

	return 0
}



# $1: ip/hostname of remote SSH server
# $2: expno
# returns 0 if OK, 1 if campaign/expno already exists
function _remote_check_campaign_expno {

	local command="ssh root@$1 sh -c \"if [ -d \"$resultsdir/${campaign}/${2}\" ]; then echo 1; else mkdir -p \"$resultsdir/${campaign}/${2}\" > /dev/null 2>&1; cp ${measurements_dir}/_settings.sh $resultsdir/${campaign}/${2}/; echo 0; fi\""

	local vvv=$( ${command} )
	#echo "found file: $vvv"
}



# $1: ip/hostname of remote SSH server
# $2: expno
# $3: measurement name
# returns 0 if OK, 1 if campaign/expno already exists
function _remote_mkdir_campaign_expno_measurementname {

	local command="ssh root@$1 sh -c \"if [ -d \"$resultsdir/${campaign}/${2}/${3}\" ]; then echo 1; else mkdir -p \"$resultsdir/${campaign}/${2}/${3}\" > /dev/null 2>&1; cp ${measurements_dir}/_settings.sh $resultsdir/${campaign}/${2}/${3}/; echo 0; fi\""

	local vvv=$( ${command} )
	#echo "found file: $vvv"
}



# $1: result var (pid)
# $2: custom text to output
# $3: variable name of command(s) to execute
# $4: 1 if command should block, otherwise not blocking
# $5: filename for log
# returns: 0
function _invoke_local {

	local __resultvar=$1
	local command=${!3}

	#echo "cmd: $command"

	if [ $4 -ne 1 ]; then
		sh -c "${command}" 2>&1 | tee -a "$5" &
	else
		sh -c "${command}" 2>&1 | tee -a "$5"
		local myresult=$!
		eval $__resultvar="'$myresult'"
		return 0
	fi

	local myresult=$!
	eval $__resultvar="'$myresult'"

	return 0
}

# $1: result var (pid)
# $2: custom text to output
# $3: variable name of command(s) to execute
# $4: ip/hostname of remote server
# $5: 1 if command should block, otherwise not blocking
# $6: filename for log
# returns: 0 if command started, 1 otherwise
function _invoke_remote {

	local __resultvar=$1
	local command=${!3}

	local ssh_command="ssh root@$4 sh -c \"${command}\""
	
	if [ $5 -ne 1 ]; then
		#echo "cmd: ${ssh_command}"
		${ssh_command} 2>&1 | tee -a "$6" &
	else
		#echo "cmd: ${ssh_command}"
		${ssh_command} 2>&1 | tee -a "$6"
		local myresult=$!
		eval $__resultvar="'$myresult'"
		return 0
	fi

	sleep 1
	
	local ssh_command_check="ssh root@$4 sh -c \"pgrep -l -f '^sh -c ${command}' | wc -l\""
	local vvv=$( ${ssh_command_check} )

	if [ "$vvv" != "1" ]; then return 1; fi
	
	local mypid=$(pgrep -f "${ssh_command}")

	if [ $mypid == "" ]; then
		echo "error: get pid of ssh command"
		return 1
	fi

	eval $__resultvar="'$mypid'"

	return 0
}

# $1: pid to wait to
# returns: 0
function _wait_for {

	#wait $1 > /dev/null 2>&1
	wait $1
	return $?
	#tail --pid="$1" -f /dev/null

	#return 0
}

# $1: measurement name
# $2: variable name of command to start sender
# $3: variable name of command to start receiver
# $4: variable name of command to kill sender
# $5: variable name of command to kill receiver
# $6: variable name of command to start gpslogger tx
# $7: variable name of command to start gpslogger rx
# $8: variable name of command to kill gpslogger tx
# $9: variable name of command to kill gpslogger rx
# $10: ip/hostname of remote server
# $11: filename for log
# $12: filename for tcpdump
# returns: 0 if measurement succesful, 1 otherwise
function _do_measurement {

	echo "______________________________________"
	echo "---> Starting measurement: $1"
	echo "--------------------------------------"

	### KILL
	cmd_tcpdump_kill="killall tcpdump"
	if [ $use_tcpdump -eq 1 ]; then
		_invoke_remote pid_kill_tcpdump_tx kill-tcpdump-$1-tx cmd_tcpdump_kill ${!10} 1 ${!11}
		if [ $? -ne 0 ]; then return 1; fi
		_invoke_local pid_kill_tcpdump_rx kill-tcpdump-$1-rx cmd_tcpdump_kill 1 ${!11}
	fi

	_invoke_remote pid_kill_measurement_tx kill-$1-tx $4 ${!10} 1 ${!11}
	if [ $? -ne 0 ]; then return 1; fi
	_invoke_local pid_kill_measurement_rx kill-$1-rx $5 1 ${!11}
	
	_invoke_local pid_kill_gpslogger_rx kill-gpslogger-$1-rx $9 1 ${!11}
	_invoke_remote pid_kill_gpslogger_tx kill-gpslogger-$1-tx $8 ${!10} 1 ${!11}
	if [ $? -ne 0 ]; then return 1; fi

	#echo "wait kill measurement_tx $pid_kill_measurement_tx"
	#_wait_for $pid_kill_measurement_tx
	#echo "wait kill_measurement_rx $pid_kill_measurement_rx"
	#_wait_for $pid_kill_measurement_rx
	#echo "wait kill gpslogger_rx $pid_kill_gpslogger_rx"
	#_wait_for $pid_kill_gpslogger_rx
	#echo "wait kill gpslogger_tx $pid_kill_gpslogger_tx"
	#_wait_for $pid_kill_gpslogger_tx
	### /KILL

	### start tcpdump
	if [ $use_tcpdump -eq 1 ]; then
		cmd_tcpdump_rx="tcpdump -i moni1 -w ${!12}"
		cmd_tcpdump_tx="tcpdump -i moni1 -w ${!12}"
		_invoke_local pid_start_tcpdump_rx start-tcpdump-$1-rx cmd_tcpdump_rx 0 ${!11}
		_invoke_remote pid_start_tcpdump_tx start-tcpdump-$1-tx cmd_tcpdump_tx ${!10} 0 ${!11}
		if [ $? -ne 0 ]; then return 1; fi
	fi
	### /start tcpdump

	_invoke_local pid_start_gpslogger_rx start-gpslogger-$1-rx $7 0 ${!11}
	_invoke_remote pid_start_gpslogger_tx start-gpslogger-$1-tx $6 ${!10} 0 ${!11}
	if [ $? -ne 0 ]; then return 1; fi
	
	_invoke_local pid_start_measurement_rx start-$1-rx $3 0 ${!11}
	_invoke_remote pid_start_measurement_tx start-$1-tx $2 ${!10} 0 ${!11}
	if [ $? -ne 0 ]; then return 1; fi

	#### Wait for input to kill measurement when doing dynamic measurments #####
	if [ $measurements_dynamic == 1 ]; then
		stopval=27
		while [ "$stopval" != 42 ]
		do
			read -e -p "Enter 42 to stop measurement: " -i "${stopval}" stopval
		done
		#sleep 20
		#read
		echo "killing measurement-tx ${pid_start_measurement_tx}"
		echo "if it hangs invoke: ssh measurements-tx ${!4}"
		#kill ${pid_start_measurement_tx}
		_invoke_remote pid_kill_measurement_tx kill-$1-tx $4 ${!10} 1 ${!11}
		if [ $? -ne 0 ]; then echo "problem"; return 1; fi
		# check return status?
	fi
	### /Wait for input to kill measurement #####

	if [ $measurements_dynamic == 0 ]; then
		echo "wait start measurement tx $pid_start_measurement_tx"
		_wait_for $pid_start_measurement_tx
		if [ $? -ne 0 ]; then return 1; fi
	fi

	echo "do next"

	_invoke_remote pid_kill_measurement_tx kill-$1-tx $4 ${!10} 1 ${!11}
	if [ $? -ne 0 ]; then return 1; fi
	_invoke_local pid_kill_measurement_rx kill-$1-rx $5 1 ${!11}
	
	_invoke_local pid_kill_gpslogger_rx kill-gpslogger-$1-rx $9 1 ${!11}
	_invoke_remote pid_kill_gpslogger_tx kill-gpslogger-$1-tx $8 ${!10} 1 ${!11}
	if [ $? -ne 0 ]; then return 1; fi

	if [ $use_tcpdump -eq 1 ]; then
		_invoke_remote pid_kill_tcpdump_tx kill-tcpdump-$1-tx cmd_tcpdump_kill ${!10} 1 ${!11}
		if [ $? -ne 0 ]; then return 1; fi
		_invoke_local pid_kill_tcpdump_rx kill-tcpdump-$1-rx cmd_tcpdump_kill 1 ${!11}
	fi

	echo "wait start gpslogger rx $pid_start_gpslogger_rx"
	_wait_for $pid_start_gpslogger_rx
	echo "wait start gpslogger tx $pid_start_gpslogger_tx"
	_wait_for $pid_start_gpslogger_tx
	echo "wait start measurement rx $pid_start_measurement_rx"
	_wait_for $pid_start_measurement_rx
	
	if [ $use_tcpdump -eq 1 ]; then
		echo "wait start tcpdump rx $pid_start_tcpdump_rx"
		_wait_for $pid_start_tcpdump_rx
		echo "wait start tcpdump tx $pid_start_tcpdump_tx"
		_wait_for $pid_start_tcpdump_tx
	fi
	#echo "wait start measurement tx $pid_start_measurement_tx"
	#_wait_for $pid_start_measurement_tx
	#echo "wait kill measurement tx $pid_kill_measurement_tx"
	#_wait_for $pid_kill_measurement_tx
	#echo "wait kill measurement rx $pid_kill_measurement_rx"
	#_wait_for $pid_kill_measurement_rx
	#echo "wait gpslogger rx $pid_kill_gpslogger_rx"
	#_wait_for $pid_kill_gpslogger_rx
	#echo "wait gpslogger tx $pid_kill_gpslogger_tx"
	#_wait_for $pid_kill_gpslogger_tx

	echo -e "\e[32m______________________________________\e[39m"
	echo -e "\e[32m###> Finished measurement: $1\e[39m"
	echo -e "\e[32m--------------------------------------\e[39m"

	sync

	return 0
}

# $1: return value of measurement function
# $2: name of measurement
# $3: expno
# $4: dist
function _check_measurement {

	local retval=$1

	if [ $retval -ne 0 ]; then
		echo -e "\e[101m\n\n\n---> measurement failed: $2\n\n\n\e[49m"
		touch ${resultsdir}/${campaign}/${3}/${2}/measurement_expno-${3}_dist-${4}_failed

		if [ $do_beep -eq 1 ]; then
			./_beep_ERR.sh
		fi

		return 1
	fi
	touch ${resultsdir}/${campaign}/${3}/${2}/measurement_expno-${3}_dist-${4}_ok
	return 0
}

function _loop_measurements {

	local expno=0
	local dist=0

	mkdir -p ${resultsdir}/${campaign}

	echo "expno, dist" >> ${resultsdir}/${campaign}/exp.log

	while true
	do
		echo "Enter experiment number to start a new measurement (or -1 to exit)"
		read -e -p "Expno: " -i "${expno}" expno

		if [ ${expno} == -1 ]; then
			echo "Exiting..."
			killall ssh
			reset
			exit 0
		fi

		echo "Enter experiment distance or angle"
		read -e -p "Dist: " -i "${dist}" dist

		if [ -d "${resultsdir}/${campaign}/${expno}" ]; then
			echo "experiment with expno ${expno} already performed, choose another expno"
			continue
		fi

		#killall ssh > /dev/null 2>&1
		_setup_ssh_master pid_ssh_master ${ssh_remote_server}
		local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> ssh master setup failed\n\n\n"; continue; fi
		#echo "ssh master pid: $pid_ssh_master, retval $retval"
		
		_remote_check_campaign_expno ${ssh_remote_server} ${expno}
		local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> ssh master setup failed: results for ${expno} already present! choose another expno!\n\n\n"; continue; fi
		
		#touch ${resultsdir}/${campaign}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv
		mkdir -p ${resultsdir}/${campaign}/${expno}
		cp ${measurements_dir}/_settings.sh $resultsdir/${campaign}/${expno}/

		curr_date=$( date -u )
		curr_date_epoch=$( date -u +"%s.%N" )
		echo -e "\e[104mXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
		echo -e "\e[104m---> Starting measurement expno: ${expno}"
		echo -e "\e[104m---> ${curr_date}"
		echo -e "\e[104m---> since epoch: ${curr_date_epoch}"
		echo -e "\e[104mXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\e[49m"
	
		filename_log="${resultsdir}/${campaign}/${expno}/log_expno-${expno}_dist-${dist}.log"

		### RSSEYE (static) ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_rsseye -eq 1 ]; then
			measurement_name="rsseye"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}

			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_rsseye_start_tx="rsseye -s -t ${rsseye_intvl} -m ${rsseye_rateidx} -a ${rsseye_numpackets} -e ${expno} -b ${bandwidth} -i moni0 -q 1"
			command_rsseye_start_rx="rsseye -r -i moni0 -q 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_rsseye_rx}_expno-${expno}_dist-${dist}.csv"

			#command_rsseye_kill_tx="pgrep -f '${command_rsseye_start_tx}' | xargs kill; killall rsseye"
			command_rsseye_kill_tx="killall rsseye"
			#command_rsseye_kill_rx="pgrep -f '${command_rsseye_start_rx}' | xargs kill; killall rsseye"
			command_rsseye_kill_rx="killall rsseye"

			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"

			_do_measurement ${measurement_name} \
				command_rsseye_start_tx \
				command_rsseye_start_rx \
				command_rsseye_kill_tx \
				command_rsseye_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /RSSEYE (static) ####

		### RSSEYE (dynamic) ###
		if [ $measurements_dynamic == 1 ] && [ $do_exp_rsseye -eq 1 ]; then
			measurement_name="rsseye"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}

			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_rsseye_start_tx="rsseye -s -t ${rsseye_intvl} -m ${rsseye_rateidx} -a ${rsseye_numpackets_infinite} -e ${expno} -b ${bandwidth} -i moni0 -q 1"
			command_rsseye_start_rx="rsseye -r -i moni0 -q 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_rsseye_rx}_expno-${expno}_dist-${dist}.csv"

			#command_rsseye_kill_tx="pgrep -f '${command_rsseye_start_tx}' | xargs kill; killall rsseye"
			command_rsseye_kill_tx="killall rsseye"
			#command_rsseye_kill_rx="pgrep -f '${command_rsseye_start_rx}' | xargs kill; killall rsseye"
			command_rsseye_kill_rx="killall rsseye"

			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"

			_do_measurement ${measurement_name} \
				command_rsseye_start_tx \
				command_rsseye_start_rx \
				command_rsseye_kill_tx \
				command_rsseye_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /RSSEYE (dynamic) ####

		### SOCKPERF_TCP ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_sockperf_tcp -eq 1 ]; then
			measurement_name="sockperf_tcp"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}

			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_sockperf_start_tx="sockperf under-load --tcp -i ${ip_rx} -t 10 --mps=max --msg-size 1000 --full-log ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_sockperf_tx}_expno-${expno}_dist-${dist}.csv"
			command_sockperf_start_rx="sockperf server --tcp > /dev/null 2>&1"
	
			#command_sockperf_kill_tx="pgrep -f '${command_sockperf_start_tx}' | xargs kill; killall sockperf"
			command_sockperf_kill_tx="killall sockperf"
			#command_sockperf_kill_rx="pgrep -f '${command_sockperf_start_rx}' | xargs kill; killall sockperf"
			command_sockperf_kill_rx="killall sockperf"

			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"
			
			_do_measurement ${measurement_name} \
				command_sockperf_start_tx \
				command_sockperf_start_rx \
				command_sockperf_kill_tx \
				command_sockperf_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /SOCKPERF_TCP ####

		### IPERF_TCP ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_iperf_tcp -eq 1 ]; then
			measurement_name="iperf_tcp"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}
	
			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"
	
			command_iperf_start_tx="iperf -c ${ip_rx} -C -f m -t 10 -y C -i 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_iperf_tx}_expno-${expno}_dist-${dist}.csv"
			command_iperf_start_rx="iperf -s -f m -C -y C -i 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_iperf_rx}_expno-${expno}_dist-${dist}.csv"
	
			#command_iperf_kill_tx="pgrep -f '${command_iperf_start_tx}' | xargs kill; killall iperf"
			command_iperf_kill_tx="killall iperf"
			#command_iperf_kill_rx="pgrep -f '${command_iperf_start_rx}' | xargs kill; killall iperf"
			command_iperf_kill_rx="killall iperf"
	
			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"
			
			_do_measurement ${measurement_name} \
				command_iperf_start_tx \
				command_iperf_start_rx \
				command_iperf_kill_tx \
				command_iperf_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /IPERF_TCP ####

		### SOCKPERF_UDP ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_sockperf_udp -eq 1 ]; then
			measurement_name="sockperf_udp"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}
	
			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_sockperf_start_tx="sockperf under-load -i ${ip_rx} -t 10 --mps=max --msg-size 1000 --full-log ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_sockperf_tx}_expno-${expno}_dist-${dist}.csv"
			command_sockperf_start_rx="sockperf server > /dev/null 2>&1"

			#command_sockperf_kill_tx="pgrep -f '${command_sockperf_start_tx}' | xargs kill; killall sockperf"
			command_sockperf_kill_tx="killall sockperf"
			#command_sockperf_kill_rx="pgrep -f '${command_sockperf_start_rx}' | xargs kill; killall sockperf"
			command_sockperf_kill_rx="killall sockperf"
	
			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"
			
			_do_measurement ${measurement_name} \
				command_sockperf_start_tx \
				command_sockperf_start_rx \
				command_sockperf_kill_tx \
				command_sockperf_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /SOCKPERF_UDP ####

		### IPERF_UDP ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_iperf_udp -eq 1 ]; then
			measurement_name="iperf_udp"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}

			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			#command_gpslogger_kill_tx="pgrep -f '${command_gpslogger_start_tx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_tx="killall gpslogger"
			#command_gpslogger_kill_rx="pgrep -f '${command_gpslogger_start_rx}' | xargs kill; killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_iperf_start_tx="iperf -u -c ${ip_rx} -b 100M -l ${iperf_udp_len} -f m -C -t 10 -y C -i 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_iperf_tx}_expno-${expno}_dist-${dist}.csv"
			command_iperf_start_rx="iperf -u -s -f m -C -y C -i 1 > ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_iperf_rx}_expno-${expno}_dist-${dist}.csv"

			#command_iperf_kill_tx="pgrep -f '${command_iperf_start_tx}' | xargs kill; killall iperf"
			command_iperf_kill_tx="killall iperf"
			#command_iperf_kill_rx="pgrep -f '${command_iperf_start_rx}' | xargs kill; killall iperf"
			command_iperf_kill_rx="killall iperf"

			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"
		
			_do_measurement ${measurement_name} \
				command_iperf_start_tx \
				command_iperf_start_rx \
				command_iperf_kill_tx \
				command_iperf_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /IPERF_UDP ####




		### SWEEP ###
		if [ $measurements_dynamic == 0 ] && [ $do_exp_sweep -eq 1 ]; then
			measurement_name="sweep_dump"
			_remote_mkdir_campaign_expno_measurementname ${ssh_remote_server} ${expno} ${measurement_name}
			local retval=$?; if [ $retval -ne 0 ]; then echo -e "\n\n\n---> error creating remote folder ${measurement_name} for measurement!\n\n\n"; continue; fi
			mkdir -p ${resultsdir}/${campaign}/${expno}/${measurement_name}

			command_gpslogger_start_tx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_tx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_start_rx="gpslogger --export ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_gpslogger_rx}_expno-${expno}_dist-${dist}.csv"
			command_gpslogger_kill_tx="killall gpslogger"
			command_gpslogger_kill_rx="killall gpslogger"

			command_sweep_start_tx="python3 /root/measurements/measure_sweep.py -t 30 -i phy2 -r ${ip_rx} -o ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_sweep_tx}_expno-${expno}_dist-${dist}.csv"
			command_sweep_start_rx="python3 /root/measurements/measure_sweep.py -i phy2 -o ${resultsdir}/${campaign}/${expno}/${measurement_name}/${filename_sweep_rx}_expno-${expno}_dist-${dist}.csv"

			command_sweep_kill_tx="killall python3"
			command_sweep_kill_rx="killall python3"

			filename_tcpdump="${resultsdir}/${campaign}/${expno}/tcpdump-${measurement_name}_expno-${expno}_dist-${dist}.pcap"
		
			_do_measurement ${measurement_name} \
				command_sweep_start_tx \
				command_sweep_start_rx \
				command_sweep_kill_tx \
				command_sweep_kill_rx \
				command_gpslogger_start_tx \
				command_gpslogger_start_rx \
				command_gpslogger_kill_tx \
				command_gpslogger_kill_rx \
				ssh_remote_server \
				filename_log \
				filename_tcpdump
			_check_measurement $? ${measurement_name} ${expno} ${dist}
			local retval=$?; if [ $retval -ne 0 ]; then continue; fi
		fi
		### /SWEEP ####




		kill $pid_ssh_master

		curr_date=$( date -u )
		curr_date_epoch=$( date -u +"%s.%N" )
		echo -e "\e[102m\n\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
		echo -e "\e[102m###> Finished measurement expno: ${expno}"
		echo -e "\e[102m###> ${curr_date}"
		echo -e "\e[102m###> since epoch: ${curr_date_epoch}"
		echo -e "\e[102mXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n\e[49m"

		if [ $do_beep -eq 1 ]; then
			./_beep_OK.sh
		fi

		echo "$expno, $dist" >> ${resultsdir}/${campaign}/exp.log
	
		((expno++))
		((dist+=dist_increment))
	done
}

# log all output of campaign to a logfile
mkdir -p ${resultsdir}/${campaign}

{
curr_date=$( date -u )
curr_date_epoch=$( date -u +"%s.%N" )
echo "-------------------------------------------------------------------------"
echo "| Measurements (RX-Side): ${campaign}"
echo "| Dynamic Measurements: ${measurements_dynamic}"
echo "| started: ${curr_date}"
echo "| since epoch: ${curr_date_epoch}"
echo "|"
echo "| Freq: ${freq} MHz"
echo "| Bandwidth: ${bandwidth} MHz"
echo "_________________________________________________________________________"

killall ssh
ssh-add /root/.ssh/${ssh_priv_key_file}

if [ $ssh_connect_third -ne 0 ]; then
	
	#udhcpc -i $internet_interface
	#ssh -N -f setup-measurements-rx
	#if [ $? -ne 0 ]; then
	#
	#	echo " failed to setup portforwardings; check internet connection"
	#	killall ssh
	#	exit 1
	#fi
	./_connect_rx.sh no-key
fi

echo -e '\n'
echo "Press enter to configure interfaces and start measurement campaign"
read

if [ $configure_interfaces -eq 1 ]; then

	echo "Configuring Interfaces..."
	./_setup_interface_client.sh
	#arp -i $wifi_interface -s ${ip_tx} ${mac_tx}
	#ip neigh add ${ip_tx} lladdr ${mac_tx} nud permanent dev $wifi_interface
fi

_loop_measurements
} 2>&1 | tee ${resultsdir}/${campaign}/measurements.log
