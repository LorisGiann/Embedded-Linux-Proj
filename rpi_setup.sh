#!/bin/bash
#Just cd into the project directory and execute the file

SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
cd ${SCR_DIR}

append () {
  echo "$1" | sudo tee -a "$2"
}

#rpi pico device
sudo usermod -a -G dialout $USER
sudo stty -F /dev/ttyACM0 115200 -ixon -ixoff

#TODO udev rule

#mosquitto
sudo apt install mosquitto mosquitto-clients
sudo systemctl enable mosquitto.service

sudo bash -c '>/etc/mosquitto/conf.d/auth.conf'
sudo bash -c 'echo "allow_anonymous false"               >> /etc/mosquitto/conf.d/auth.conf'
sudo bash -c 'echo "password_file /etc/mosquitto/pwfile" >> /etc/mosquitto/conf.d/auth.conf'
sudo bash -c 'echo "listener 1883"                       >> /etc/mosquitto/conf.d/auth.conf'

echo "Enter the password for mqtt broker:"
sudo mosquitto_passwd -c /etc/mosquitto/pwfile pi #enter the password
sudo systemctl restart mosquitto.service

# Influx DB
sudo apt install influxdb influxdb-client
sudo systemctl unmask influxdb
sudo systemctl enable influxdb
sudo systemctl start influxdb

#Setup Grafana (Graph Data from DB)
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server


# Setup Influx DB and telegraph
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt update
sudo apt install telegraf
sudo systemctl enable telegraf

TELEGRAPH_CONF_FILE="/etc/telegraf/telegraf.d/plantWateringEMLI.conf"
sudo bash -c ">${TELEGRAPH_CONF_FILE}"

append '[[outputs.influxdb]]' "${TELEGRAPH_CONF_FILE}"
append '        urls = ["http://127.0.0.1:8086"]' "${TELEGRAPH_CONF_FILE}"
append '        database = "emli_project"' "${TELEGRAPH_CONF_FILE}"
append '        username = "telegraf"' "${TELEGRAPH_CONF_FILE}"
append '        password = "emli"' "${TELEGRAPH_CONF_FILE}"

append '[[inputs.mqtt_consumer]]' "${TELEGRAPH_CONF_FILE}"
append 'servers = ["tcp://localhost:1883"]' "${TELEGRAPH_CONF_FILE}"
append 'username = "pi"' "${TELEGRAPH_CONF_FILE}"
append 'password = "raspberry"' "${TELEGRAPH_CONF_FILE}"
append 'data_format = "value"' "${TELEGRAPH_CONF_FILE}"
append 'data_type = "integer"' "${TELEGRAPH_CONF_FILE}"
append 'topics = [' "${TELEGRAPH_CONF_FILE}"
append '        "plant0/soil_moisture",' "${TELEGRAPH_CONF_FILE}"
append '        "plant0/ambient_light",' "${TELEGRAPH_CONF_FILE}"
append '        "plant0/plant_alarm",' "${TELEGRAPH_CONF_FILE}"
append '        "plant0/pump_alarm",' "${TELEGRAPH_CONF_FILE}"
append '        "plant0/pump_req",' "${TELEGRAPH_CONF_FILE}" #TO BE CHANGED!
append '        "sys_health/percent_cpu",' "${TELEGRAPH_CONF_FILE}"
append '        "sys_health/percent_mem",' "${TELEGRAPH_CONF_FILE}"
append '        "sys_health/temp_cpu",' "${TELEGRAPH_CONF_FILE}"
append '        "sys_health/percent_disk",' "${TELEGRAPH_CONF_FILE}"
append '        "sys_health/internet_perf",' "${TELEGRAPH_CONF_FILE}"
append '	"sys_health/internet_speed"' "${TELEGRAPH_CONF_FILE}"
append ']' "${TELEGRAPH_CONF_FILE}"


# Setup a unit file to start the script at startup
UNIT_FILE=/lib/systemd/system/plantWatering.service
sudo bash -c ">${UNIT_FILE}"

append "[Unit]" "${UNIT_FILE}"
append "Description=plant watering system project" "${UNIT_FILE}"
append "Requires=mosquitto.service" "${UNIT_FILE}"
append "After=mosquitto.service" "${UNIT_FILE}"
append "[Service]" "${UNIT_FILE}"
append "ExecStart=$PWD/launcher.sh >/dev/null 2>&1" "${UNIT_FILE}"
append "[Install]" "${UNIT_FILE}"
append "WantedBy=default.target" "${UNIT_FILE}"

sudo systemctl daemon-reload
sudo systemctl enable plantWatering.service
sudo systemctl start plantWatering.service
sudo systemctl status plantWatering.service


# Setup a unit file for WiFI at startup
UNIT_FILE=/lib/systemd/system/wifi-router.service
~/Documents/Embedded-Linux-Proj/WIFIRouter.sh
sudo bash -c ">${UNIT_FILE}"

append "[Unit]" "${UNIT_FILE}"
append "Description=start wifi Access Point" "${UNIT_FILE}"
append "After=network-online.target" "${UNIT_FILE}"
append "[Service]" "${UNIT_FILE}"
append "ExecStart=$PWD/WIFIRouter.sh >/dev/null 2>&1" "${UNIT_FILE}"
append "[Install]" "${UNIT_FILE}"
append "WantedBy=default.target" "${UNIT_FILE}"

sudo systemctl daemon-reload
sudo systemctl enable wifi-router.service
sudo systemctl start wifi-router.service
sudo systemctl status wifi-router.service

