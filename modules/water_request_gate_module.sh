#!/bin/bash

#constants / definitions
DEV=$1
PICO_DEVICE_FILE=$2

PUMP_REQ_TOPIC=$DEV/pump_req
PUMP_ALARM_TOPIC=$DEV/pump_alarm


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#local variables (maintain state between messages)
PUMP_ALARM="0" #suppose no alarm at system startup

mosquitto_sub -h localhost -p 1883 -t $PUMP_REQ_TOPIC -t $PUMP_ALARM_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do 
	#echo "From \"$TOPIC\": \"$MESSAGE\""

	if [[ $TOPIC == $PUMP_ALARM_TOPIC ]] ; then
		if [[ $MESSAGE == "0" || $MESSAGE == "1" ]] ; then
			PUMP_ALARM=$MESSAGE
			echo "Setting PUMP_ALARM to $PUMP_ALARM"
		else
			echo "ERROR: invalid message in $PUMP_ALARM_TOPIC" | tee /dev/stderr 
		fi
	elif [[ $TOPIC == $PUMP_REQ_TOPIC ]] ; then
		if [[ $PUMP_ALARM == "0" ]] ; then
			echo "Pump request ACCEPTED"
			echo "p" > $PICO_DEVICE_FILE
		else
			echo "Pump request REJECTED"
		fi
	else
		echo "ERROR: not recognized topic!" | tee /dev/stderr 
	fi
		
done
