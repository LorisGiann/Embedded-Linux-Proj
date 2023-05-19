#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#DEFINITIONS
#the following associative array consists in:
# - a list of keys identifying the MQTT topics folder in which informations regarding a plant are published
# - for each key the device file for the pico assiciated with the plant is specified
declare -A DEVS
DEVS["dev0"]="/dev/ttyACM0"

MODULES_DIR="modules"
LOGS_DIR="logs"


rm -rf $LOGS_DIR > /dev/null 2>&1 # Initialize a directory for logs
pids=()  # Initialize an empty array to hold the PIDs of the background processes

#start a new process and log it
#Each instance is launched in a new session so that all subprocesses can be terminated at a later time by sending the signal to the relevant process group
launch_daemon() {
    local COMMAND=$1
    local LOG_FILE=$2
    # create a temporary anonymus pipe to make the process to launch and the logger communicate each other
    PIPE=$(mktemp -u)
    mkfifo $PIPE
    setsid $COMMAND >"$PIPE" 2>&1 & pid1=$!
    ./log2file.sh "$LOG_FILE" 10000 2 <"$PIPE" &
    # unlink the named pipe (will effectively be removed once the first command terminates)
    rm $PIPE
    #save the pid
    pids+=($pid1)
}


#start by appending the RPI system health log module
launch_daemon "./$MODULES_DIR/log_module.sh" "$LOGS_DIR/log_module.sh.log"
#setsid ./$MODULES_DIR/log_module.sh > >(./log2file.sh $LOGS_DIR/log_module.sh.log 10000 2) 2>&1 & #> logs/log_module.sh.log 2>&1 &
#pids+=($!)

#Iterate over each device to launch an istance of all the modules
for DEV in "${!DEVS[@]}"
do
	#echo "Key: $DEV, Value: ${DEVS[$DEV]}"
	echo "Starting modules processes for $DEV..."

	#"receiving" modules (edge devs -> system core)
	launch_daemon "./$MODULES_DIR/pico_read_module.sh $DEV ${DEVS[$DEV]}" "$LOGS_DIR/$DEV/pico_read_module.sh.log"
	#setsid ./$MODULES_DIR/pico_read_module.sh $DEV ${DEVS[$DEV]} > >(./log2file.sh $LOGS_DIR/$DEV/pico_read_module.sh.log 10000 2) 2>&1 & #> logs/pico_read_module.sh.log 2>&1 &
	#pids+=($!)
	launch_daemon "./$MODULES_DIR/button_water_module.sh $DEV" "$LOGS_DIR/$DEV/button_water_module.sh.log"
	#setsid ./$MODULES_DIR/button_water_module.sh $DEV > >(./log2file.sh $LOGS_DIR/$DEV/button_water_module.sh.log 10000 2) 2>&1 & #> logs/button_water_module.sh.log 2>&1 &
	#pids+=($!)
	
	#"actuation" modules (system core -> edge devs)
	launch_daemon "./$MODULES_DIR/water_request_gate_module.sh $DEV ${DEVS[$DEV]}" "$LOGS_DIR/$DEV/water_request_gate_module.sh.log"
	#setsid ./$MODULES_DIR/water_request_gate_module.sh $DEV ${DEVS[$DEV]} > >(./log2file.sh $LOGS_DIR/$DEV/water_request_gate_module.sh.log 10000 2) 2>&1 & #> logs/water_request_gate_module.sh.log 2>&1 &
	#pids+=($!)
	launch_daemon "./$MODULES_DIR/led_module.sh $DEV ${DEVS[$DEV]}" "$LOGS_DIR/$DEV/led_module.sh.log"
	#setsid ./$MODULES_DIR/led_module.sh $DEV ${DEVS[$DEV]} > >(./log2file.sh $LOGS_DIR/$DEV/led_module.sh.log 10000 2) 2>&1 & #> logs/led_module.sh.log 2>&1 &
	#pids+=($!)
	
	#processing / event generation modules
	launch_daemon "./$MODULES_DIR/moisture_water_module.sh $DEV" "$LOGS_DIR/$DEV/moisture_water_module.sh.log"
	#setsid ./$MODULES_DIR/moisture_water_module.sh $DEV > >(./log2file.sh $LOGS_DIR/$DEV/moisture_water_module.sh.log 10000 2) 2>&1 & #> logs/moisture_water_module.sh.log 2>&1 &
	#pids+=($!)
	launch_daemon "./$MODULES_DIR/regular_water_module.sh $DEV" "$LOGS_DIR/$DEV/regular_water_module.sh.log"
	#setsid ./$MODULES_DIR/regular_water_module.sh $DEV > >(./log2file.sh $LOGS_DIR/$DEV/regular_water_module.sh.log 10000 2) 2>&1 & #> logs/regular_water_module.sh.log 2>&1 &
	#pids+=($!)
	
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

