#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#DEFINITIONS
#the following associative array consists in:
# - a list of keys identifying the MQTT topics folder in which informations regarding a plant are published
# - for each key the device file for the pico assiciated with the plant is specified
declare -A DEVS
DEVS["dev0"]="/home/loris/Documents/Embedded-Linux-Proj/devttyACM0"


pids=()  # Initialize an empty array to hold the PIDs of the background processes
rm -rf logs > /dev/null 2>&1 # Initialize a directory for logs
mkdir logs

#start by appending the RPI system health log module
./log_module.sh > logs/log_module.sh.log 2>&1 &
pids+=($!)

#Iterate over each device to launch an istance of all the modules
for DEV in "${!DEVS[@]}"
do
	#echo "Key: $DEV, Value: ${DEVS[$DEV]}"
	echo "Starting modules processes for $DEV..."
	
	#"receiving" modules (edge devs -> system core)
	./pico_read_module.sh $DEV ${DEVS[$DEV]} > logs/pico_read_module.sh.log 2>&1 &
	pids+=($!)
	./button_water_module.sh $DEV > logs/button_water_module.sh.log 2>&1 &
	pids+=($!)
	
	#"actuation" modules (system core -> edge devs) 
	./water_request_gate_module.sh $DEV ${DEVS[$DEV]} > logs/water_request_gate_module.sh.log 2>&1 &
	pids+=($!)
	#./led_module.sh $DEV ${DEVS[$DEV]} > logs/led_module.sh.log 2>&1 &
	#pids+=($!)
	
	#processing / event generation modules
	./moisture_water_module.sh $DEV > logs/moisture_water_module.sh.log 2>&1 &
	pids+=($!)
	./regular_water_module.sh $DEV > logs/regular_water_module.sh.log 2>&1 &
	pids+=($!)
	
done


echo "Background modules processes started (PIDs: ${pids[@]})"

# Wait for user input to terminate the background processes
echo "Press any key to terminate the system"
read -n 1 -s

# Kill all the background processes using their PIDs
echo "Terminating background processes..."
for pid in "${pids[@]}"; do
  kill $pid
done
echo "Background processes terminated"

