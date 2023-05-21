#!/bin/bash

#constants
TOPIC_ROOT=sys_health #topic root in which to publish metrics
FREQUENCY=60 #publish measuremets every X seconds


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#create an associative array in which metrix will be put
declare -A METRICS


while true ; do
	#CPU usage and temperature
	METRICS["percent_cpu"]=$(top -bn1 | awk '/Cpu/{print $2}')
	#METRICS["temp_cpu"]=$(/usr/bin/vcgencmd measure_temp) #works on raspbian
	METRICS["temp_cpu"]=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))  #works on ubuntu 

	#RAM usage
	available_mem=$(free | grep Mem | awk '{print $3}')
	used_mem=$(free | grep Mem | awk '{print $2}')
	METRICS["percent_mem"]=$((available_mem*100 / used_mem))

	#used space in root directory
	METRICS["percent_disk"]=$(df --output=target,ipcent | grep -E '^/[[:blank:]]+' | awk '{print $2}' | tr -d \%)

	#internet is reachable?
	
	if ping -q -c 1 -W 2 8.8.8.8 >/dev/null; then
		RES=1
	else
		RES=0
	fi
	METRICS["internet_perf"]=$RES


	for metric in "${!METRICS[@]}"
	do
		val=${METRICS[$metric]}
		echo "$metric: $val"
		./mqtt_pub.sh $TOPIC_ROOT/$metric $val
	done

	sleep $FREQUENCY
done
