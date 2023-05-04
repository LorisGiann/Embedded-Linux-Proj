SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
echo $SCR_DIR

while [ true ]; do
	# Read device for commas separated values
	args=$(timeout 1s cat /dev/ttyACM0)
	#echo "${args} read"
	
	# Replace commas with spaces
	args=$(echo $args | sed 's/,/ /g')
	#echo "${args} modified "
	
	# Feed into publish script (uses each value as an arguement)
	${SCR_DIR}/pub_values.sh ${args}
	#echo done
done
