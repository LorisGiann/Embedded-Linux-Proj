#!/bin/bash

#constants / definitions
DEV=$1
PUMP_REQ_TOPIC=$DEV/pump_req
WAIT_FOR_SECONDS=$((12*60*60)) #every 12h
PRINT_EVERY_SECONDS=10


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#local variables (maintain state between messages)
remaining=$WAIT_FOR_SECONDS

while true; do
	
	if [[ $remaining -gt 0 ]]; then
		# Convert remaining time to hours, minutes, and seconds
		hours=$((remaining / 3600))
		minutes=$(( (remaining % 3600) / 60 ))
		seconds=$((remaining % 60))
		echo "Remaining time: $hours hours, $minutes minutes, $seconds seconds"
		# Wait for a minute
		sleep $PRINT_EVERY_SECONDS
		# Calculate the remaining time in seconds    	
		remaining=$((remaining-PRINT_EVERY_SECONDS))
	else 
		echo "Time elapsed!"
		./mqtt_pub.sh $PUMP_REQ_TOPIC "Req($0)"
		remaining=$WAIT_FOR_SECONDS
	fi

done
