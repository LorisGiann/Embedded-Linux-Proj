#!/bin/bash

#constants / definitions
DEV=$1
PICO_DEVICE_FILE=$2

PUMP_CMD_TOPIC=$DEV/pump_cmd


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

mosquitto_sub -h localhost -p 1883 -t $PUMP_CMD_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do 
	#echo "From \"$TOPIC\": \"$MESSAGE\""

	if [[ $TOPIC == $PUMP_CMD_TOPIC ]] ; then
		if [[ $MESSAGE == "1" ]] ; then
			echo "Activating pump (time: $(date))"
			echo "p" > $PICO_DEVICE_FILE
		else
			echo "ERROR: invalid message \"$MESSAGE\" in $PUMP_ALARM_TOPIC (\"1\" expected)" | tee /dev/stderr 
		fi
	else
		echo "ERROR: not recognized topic!" | tee /dev/stderr 
	fi
		
done
