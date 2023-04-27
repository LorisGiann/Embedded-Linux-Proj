SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
# echo ${SCR_DIR}

pub=${SCR_DIR}/mqtt_pub.sh

${pub} dev0/water_alarm $1

${pub} dev0/plant_alarm $2

${pub} dev0/soil_moisture $3

${pub} dev0/ambient_light $4

