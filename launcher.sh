#!/bin/bash

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

#DEFINITIONS
#the following array contains the following parameters for each plant:
# - the identifying plant name, which corresponds to the MQTT topic prefix in which informations regarding that plant are published
# - the device file for the pico assiciated with the plant
# - the % threshold under which the soil moisture is considered low
#do not put spaces in any of these fields!
PLANTS=()
declare -A PLANT
PLANT["name"]="plant0"
PLANT["dev"]="/dev/ttyACM0"
PLANT["soil_thresh"]=45
PLANTS+=PLANT
#declare -A PLANT
#PLANT["name"]="plant1"
#PLANT["dev"]="/dev/ttyACM1"
#PLANT["soil_thresh"]=60
#PLANTS+=PLANT


MODULES_DIR="modules"
LOGS_DIR="logs"


rm -rf $LOGS_DIR > /dev/null 2>&1 # Initialize a directory for logs
pids=()  # Initialize an array to hold the PIDs of the background processes
pipes=() # Initialize an array to hold used named pipes

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
    #save the pipe name to schedule unlink of the named pipe during cleanup
    pipes+=($PIPE)
    #save the pid to schedule process termination during cleanup
    pids+=($pid1)
}


#start by appending the RPI system health log module
launch_daemon "./$MODULES_DIR/log_module.sh" "$LOGS_DIR/log_module.sh.log"

#Iterate over each device to launch an istance of all the modules
for PLANT in "${PLANTS[@]}"
do
	echo "Starting modules processes for $PLANT..."

	#"receiving" modules (edge devs -> system core)
	launch_daemon "./$MODULES_DIR/pico_read_module.sh ${PLANT['name']} ${PLANT['dev']}" "$LOGS_DIR/${PLANT['name']}/pico_read_module.sh.log"
	launch_daemon "./$MODULES_DIR/button_water_module.sh ${PLANT['name']}" "$LOGS_DIR/${PLANT['name']}/button_water_module.sh.log"
	
	#"actuation" modules (system core -> edge devs)
	launch_daemon "./$MODULES_DIR/pico_write_module.sh ${PLANT['name']} ${PLANT['dev']}" "$LOGS_DIR/${PLANT['name']}/pico_write_module.sh.log"
	launch_daemon "./$MODULES_DIR/led_module.sh ${PLANT['name']} ${PLANT['soil_thresh']}" "$LOGS_DIR/${PLANT['name']}/led_module.sh.log"
	
	#processing / event generation modules
	launch_daemon "./$MODULES_DIR/moisture_water_module.sh ${PLANT['name']} ${PLANT['soil_thresh']}" "$LOGS_DIR/${PLANT['name']}/moisture_water_module.sh.log"
	launch_daemon "./$MODULES_DIR/regular_water_module.sh ${PLANT['name']}" "$LOGS_DIR/${PLANT['name']}/regular_water_module.sh.log"
	launch_daemon "./$MODULES_DIR/water_request_gate_module.sh ${PLANT['name']}" "$LOGS_DIR/${PLANT['name']}/water_request_gate_module.sh.log"
	
done


echo "Background modules processes started (PIDs: ${pids[@]})"
ps fj -P ${pids[@]}
echo "(Current launcher process PID: $$)"


# Wait for user input to terminate the background processes
#echo "Press any key to terminate the system"
#read -n 1 -s

#wait until SIGTERM (CRTL+C) is received
sleep infinity & PID=$!
trap "kill $PID" INT TERM
wait   #the launched process will wait for the "sleep infinity" process to finish, which happens as soon as SIGTERM is received


# Kill all the background processes using their PIDs
echo "Terminating background processes..."
for PID in "${pids[@]}"; do
	PGID=$(ps opgid= "$PID" | tr -d ' ') #get the whole process group of the session with the launghed command. Tipically PGID is the same of the root PID
	if [ -z "$PGID" ]; then continue; fi
	kill -SIGTERM -$PGID #term all the processes of the group
done
echo "Closing named pipes..."
for PIPE in "${pipes[@]}"; do
	rm $PIPE
done
echo "Background processes terminated"
ps fj -P ${pids[@]}

