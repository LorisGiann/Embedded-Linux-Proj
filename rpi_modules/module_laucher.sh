#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#DEFINITIONS
#the following associative array consists in:
# - a list of keys identifying the MQTT topics folder in which informations regarding a plant are published
# - for each key the device file for the pico assiciated with the plant is specified
declare -A DEVS
DEVS["dev0"]="/dev/ttyACM0"


pids=()  # Initialize an empty array to hold the PIDs of the background processes
rm -rf logs > /dev/null 2>&1 # Initialize a directory for logs
mkdir logs

#Each instance is launched in a new session so that all subprocesses can be terminated at a later time by sending the signal to the relevant process group

#start by appending the RPI system health log module
setsid ./log_module.sh > logs/log_module.sh.log 2>&1 &
pids+=($!)

#Iterate over each device to launch an istance of all the modules
for DEV in "${!DEVS[@]}"
do
	#echo "Key: $DEV, Value: ${DEVS[$DEV]}"
	echo "Starting modules processes for $DEV..."
	
	#"receiving" modules (edge devs -> system core)
	setsid ./pico_read_module.sh $DEV ${DEVS[$DEV]} > logs/pico_read_module.sh.log 2>&1 &
	pids+=($!)
	setsid ./button_water_module.sh $DEV > logs/button_water_module.sh.log 2>&1 &
	pids+=($!)
	
	#"actuation" modules (system core -> edge devs) 
	setsid ./water_request_gate_module.sh $DEV ${DEVS[$DEV]} > logs/water_request_gate_module.sh.log 2>&1 &
	pids+=($!)
	#setsid ./led_module.sh $DEV ${DEVS[$DEV]} > logs/led_module.sh.log 2>&1 &
	#pids+=($!)
	
	#processing / event generation modules
	setsid ./moisture_water_module.sh $DEV > logs/moisture_water_module.sh.log 2>&1 &
	pids+=($!)
	setsid ./regular_water_module.sh $DEV > logs/regular_water_module.sh.log 2>&1 &
	pids+=($!)
	
done


echo "Background modules processes started (PIDs: ${pids[@]})"
ps fj -P ${pids[@]}

# Wait for user input to terminate the background processes
echo "Press any key to terminate the system"
read -n 1 -s

# Kill all the background processes using their PIDs
echo "Terminating background processes..."
for PID in "${pids[@]}"; do
	PGID=$(ps opgid= "$PID" | tr -d ' ') #get the whole process group of the session with the launghed command. Tipically PGID is the same of the root PID
	if [ -z "$PGID" ]; then continue; fi
	kill -SIGTERM -$PGID #term all the processes of the group
done
echo "Background processes terminated"
ps fj -P ${pids[@]}

