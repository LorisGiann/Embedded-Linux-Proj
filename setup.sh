#!/bin/bash

sudo usermod -a -G dialout $USER
sudo stty -F /dev/ttyACM0 115200 -ixon -ixoff

sudo apt install mosquitto mosquitto-clients
sudo systemctl enable mosquitto.service

sudo touch /etc/mosquitto/conf.d/auth.conf
sudo bash -c 'echo "allow_anonymous false"               >> /etc/mosquitto/conf.d/auth.conf'
sudo bash -c 'echo "password_file /etc/mosquitto/pwfile" >> /etc/mosquitto/conf.d/auth.conf'
sudo bash -c 'echo "listener 1883"                       >> /etc/mosquitto/conf.d/auth.conf'

echo "Enter the password for mqtt broker:"
sudo mosquitto_passwd -c /etc/mosquitto/pwfile pi #enter the password
sudo systemctl restart mosquitto.service

