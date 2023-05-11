#!/bin/bash

#constants / definitions
DEV=$1 # Pass in device as first argument


#topics to subscribe
__1_TOPIC=$DEV/__topic_1__
__2_TOPIC=$DEV/__topic_2__

#topics to write to
OUT_TOPIC=$DEV/__topic_3__

#local variables (maintain state between messages)


mosquitto_sub -h localhost -p 1883 -t $__1_TOPIC -t $__2_TOPIC -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do 
	#echo "From \"$TOPIC\": \"$MESSAGE\""

	if [[ $TOPIC == $__1_TOPIC ]] ; then
                ...
		./mqtt_pub.sh $OUT_TOPIC "Req($0)"
		...
        elif [[ $TOPIC == $__2_TOPIC ]] ; then
        	...
		./mqtt_pub.sh $OUT_TOPIC "Req($0)"
		...
	else
                echo "ERROR: not recognized topic!" | tee /dev/stderr
        fi
done
