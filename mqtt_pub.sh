mosquitto_pub -h localhost -p 1883 -t $1 -m $2 -u pi -P raspberry

scr_dir=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
echo ${scr_dir}
