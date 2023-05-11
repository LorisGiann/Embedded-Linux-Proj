# Sets the MQTT topic for only one led at a time, disables others
# $1 is the device, $2 is the led to set (0=green, 1=yellow, 2=red)

DEV=$1

topics=($DEV/led/green $DEV/led/yellow $DEV/led/red)

for i in 0 1 2
do
	if [[ ${2} == ${i} ]] ; then
		./mqtt_pub.sh ${topics[$i]} 1
	else
		./mqtt_pub.sh ${topics[$i]} 0
	fi
done
