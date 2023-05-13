#!/bin/bash

# Used to edit which MQTT topics are monitored and saved to InfluxDB
# Inputs (MQTT Topics) are controlled by '[[inputs.mqtt_consumer]]' section
# Outputs (InfluxDB) controlled by '[[outputs.influxdb]]' section
# Use find to jump to these sections to edit them

sudo vim /etc/telegraf/telegraf.conf
