#!/bin/bash

#constants / definitions
DEV=$1
MOISTURE_THRESH=40 #water pump is activated every hour if moisture falls below this percentage
MAX_RUN_FREQ=3600  #pump is activated not more often than once every X seconds

#topics to subscribe
SOIL_MOISTURE_TOPIC=$DEV/soil_moisture  # a value between 0 and 100 is expected (100 = max hum)

#topics to write to
PUMP_REQ_TOPIC=$DEV/pump_req

#local variables (maintain state between messages)
LAST_RUN="0" #last time that pump was activated

mosquitto_sub -h localhost -p 1883 -t $SOIL_MOISTURE_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do
        #echo "From \"$TOPIC\": \"$MESSAGE\""
	
	#main logic: if below threshold run the pump (if it wasn't activated less than 1h ago)
        if [[ $TOPIC == $SOIL_MOISTURE_TOPIC ]] ; then
		if [[ (! $MESSAGE =~ ^[0-9]+$ ) || $MESSAGE -lt 0 || $MESSAGE -gt 100 ]] ; then
			echo "ERROR: message \"$MESSAGE\" received in \"$TOPIC\" is not valid: expected a number between 0 and 100!" | tee /dev/stderr
			continue
		fi
		current_time=$(date +%s)
		if [[ $MESSAGE -lt $MOISTURE_THRESH ]] ; then
			echo "Soil below threshold ..."
			if [[ $((LAST_RUN + MAX_RUN_FREQ)) -le $current_time ]] ; then 
				echo "... activating pump (last activation $((current_time-$LAST_RUN)) seconds ago)"
				LAST_RUN=$current_time
				./mqtt_pub.sh $PUMP_REQ_TOPIC "Req($0)"
			else
				echo "... skipping pump activation (last activation $((current_time-$LAST_RUN)) seconds ago)"
			fi
		else
			echo "Soil moisture OK"
		fi

        else
                echo "ERROR: not recognized topic!" | tee /dev/stderr
        fi
done
