#!/bin/bash

#constants / definitions
DEV=$1
MAX_RUN_FREQ=2  #pump is activated not more often than once every X seconds

#topics to subscribe
SOIL_MOISTURE_TOPIC=$DEV/button  # a value between 0 and 100 is expected (100 = max hum)

#topics to write to
PUMP_REQ_TOPIC=$DEV/pump_req

#local variables (maintain state between messages)
LAST_RUN="0" #last time that pump was activated

mosquitto_sub -h localhost -p 1883 -t $SOIL_MOISTURE_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do
        #echo "From \"$TOPIC\": \"$MESSAGE\""
	
	#main logic: if button has been pressed at least once, activate the pump (if it wasn't activated less than MAX_RUN_FREQ seconds ago)
        if [[ $TOPIC == $SOIL_MOISTURE_TOPIC ]] ; then
		if [[ (! $MESSAGE =~ ^[0-9]+$ ) || $MESSAGE -lt 0 ]] ; then
			echo "ERROR: message \"$MESSAGE\" received in \"$TOPIC\" is not valid: expected a number >= 0" | tee /dev/stderr
			continue
		fi
		current_time_nanosec=$(date +%s%N)
		if [[ $MESSAGE -gt 0 ]] ; then
			echo "Button pressed ..."
			if [[ $((LAST_RUN + (MAX_RUN_FREQ*1000000000))) -le $current_time_nanosec ]] ; then 
				echo "... activating pump (last activation $((current_time_nanosec - LAST_RUN)) nanoseconds ago)"
				LAST_RUN=$current_time_nanosec
				./mqtt_pub.sh $PUMP_REQ_TOPIC "Req($0)"
			else
				echo "... skipping pump activation (last activation $((current_time_nanosec - LAST_RUN)) nanoseconds ago)"
			fi
		fi
	else
                echo "ERROR: not recognized topic!" | tee /dev/stderr
        fi
done
