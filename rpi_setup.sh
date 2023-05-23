#!/bin/bash
#Just cd into the project directory and execute the file

sudo usermod -a -G dialout $USER
sudo stty -F /dev/ttyACM0 115200 -ixon -ixoff

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

# Setup Influx DB (Store MQTT commands to DB)
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt update
sudo apt install telegraf
sudo systemctl enable telegraf


# Setup a unit file to start the script at startup
UNIT_FILE=/lib/systemd/system/plantWatering.service
sudo bash -c ">${UNIT_FILE}"

append () {
  echo "$1" | sudo tee -a "${UNIT_FILE}"
}

append "[Unit]"
append "Description=plant watering system project"
append "Requires=mosquitto.service"
append "After=mosquitto.service"
append "[Service]"
append "ExecStart=$PWD/launcher.sh >/dev/null 2>&1"
append "[Install]"
append "WantedBy=default.target"

sudo systemctl daemon-reload
sudo systemctl enable plantWatering.service
sudo systemctl start plantWatering.service
sudo systemctl status plantWatering.service
