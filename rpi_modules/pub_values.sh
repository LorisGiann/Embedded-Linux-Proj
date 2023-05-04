
#constants / definitions
DEV=$1


SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}
#pub=${SCR_DIR}/mqtt_pub.sh
#echo ${SCR_DIR}

./mqtt_pub.sh $DEV/pump_alarm $2

./mqtt_pub.sh $DEV/plant_alarm $3

./mqtt_pub.sh $DEV/soil_moisture $4

./mqtt_pub.sh $DEV/ambient_light $5

