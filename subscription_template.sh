#!/bin/bash
mosquitto_sub -h localhost -p 1883 -t dev0/button -t dev0/pump_alarm -d -u pi -P raspberry -F "%t %p" | grep -vE --line-buffered '^Client|^Subscribed' | while read TOPIC MESSAGE 
do 
	echo $TOPIC
	echo $MESSAGE
done
