#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}
#echo $SCR_DIR

#constants / definitions
DEV=$1
PICO_DEVICE_FILE=$2

while [ true ]; do
	# Read device for commas separated values
	args=$(timeout 1s cat ${PICO_DEVICE_FILE})
	#echo "${args} read"
	
	# Replace commas with spaces
	args=$(echo $args | sed 's/,/ /g')
	#echo "${args} modified "
	
	# Feed into publish script (uses each value as an arguement)
	./pub_values.sh $DEV ${args}
	#echo done
	
	
	sleep 5
done
