SCR_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
echo $SCR_DIR
args=$(timeout 1s cat /dev/ttyACM0)
echo "${args} read"
args=$(echo $args | sed 's/,/ /g')
echo "${args} modified "
${SCR_DIR}/pub_values.sh ${args}
echo done
