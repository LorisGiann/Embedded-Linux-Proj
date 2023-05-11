#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}
#echo $SCR_DIR

#constants / definitions
DEV=$1
PICO_DEVICE_FILE=$2
i=0
TOPICS[$((i++))]="pump_alarm"
TOPICS[$((i++))]="plant_alarm"
TOPICS[$((i++))]="soil_moisture"
TOPICS[$((i++))]="ambient_light"

cat ${PICO_DEVICE_FILE} | grep -E --line-buffered '^[0-1],[0-1],[0-9]{1,3},[0-9]{1,3}$' | while read LINE ; do	
	# Each lines consists in a collection of comma separeted values: replace commas with spaces
	values=$(echo $LINE | sed 's/,/ /g')
	
	# publish each value on relevant topic
	TOPIC_NUM=0
	for value in $values; do
	  ./mqtt_pub.sh $DEV/${TOPICS[$TOPIC_NUM]} $value
	  #echo "$DEV/${TOPICS[$TOPIC_NUM]} $value"
	  ((TOPIC_NUM++))
	done
done
