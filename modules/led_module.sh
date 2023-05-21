#!/bin/bash

#constants / definitions
DEV=$1 # Pass in device as first argument
MOISTURE_THRESHOLD=$2 # % under which soil moisture is considered low

#topics to subscribe
PUMP_TOPIC=$DEV/pump_alarm
PLANT_TOPIC=$DEV/plant_alarm
SOIL_TOPIC=$DEV/soil_moisture

#topics to write to
GREEN_TOPIC=$DEV/led/green
YELLOW_TOPIC=$DEV/led/yellow
RED_TOPIC=$DEV/led/red


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#local variables (maintain state between messages)
PLANT_ALARM=1 #defensive: suppose there's an alarm at startup before receiving any message
PUMP_ALARM=1 #defensive: suppose there's an alarm at startup before receiving any message
SOIL_MOISTURE=0

mosquitto_sub -h localhost -p 1883 -t $PLANT_TOPIC -t $PUMP_TOPIC -t $SOIL_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do 
	echo "From \"$TOPIC\": \"$MESSAGE\""

	if [[ $TOPIC == $PLANT_TOPIC ]] ; then
		PLANT_ALARM=$MESSAGE
        elif [[ $TOPIC == $PUMP_TOPIC ]] ; then
        	PUMP_ALARM=$MESSAGE
	elif [[ $TOPIC == $SOIL_TOPIC ]] ; then
		SOIL_MOISTURE=$MESSAGE
	else
                echo "ERROR: not recognized topic!" | tee /dev/stderr
        fi

	echo "soil: $SOIL_MOISTURE, plant: $PLANT_ALARM, pump: $PUMP_ALARM"

	if [ ${PUMP_ALARM} == 1 ] || [ ${PLANT_ALARM} == 1 ] ; then
		./set_led.sh $DEV 2
	elif [[ ${SOIL_MOISTURE} -lt ${MOISTURE_THRESHOLD} ]] ; then
		./set_led.sh $DEV 1
	else
		./set_led.sh $DEV 0
	fi
done
