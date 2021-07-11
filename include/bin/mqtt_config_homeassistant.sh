#!/bin/sh

source ./mqtt_functions.sh

setup_topic(){
# object type, topic name
[ -n "${MQTT_HOMEASSISTANT}" ] && BASETOPIC="${MQTT_HOMEASSISTANT}"
echo -n "${BASETOPIC:-homeassistant}/$1/`mqtt_base_uniqueid $2`/config"
}

setup_device_base(){
echo -n {\""identifiers\"":[\""wibox_${MODEL}\""],\""name\"":\""${MODEL}\"",\""model\"":\""WiBox 7938\"",\""manufacturer\"":\""Fermax\"",\""suggested_area\"":\""Entrance\""}
}

setup_switch_message(){
# topic, name, icon, availabilty_topic_root (false)
TOPIC="`mqtt_base_topic`/$1"
AVTOPIC="${TOPIC}"
[ -n "$4" ] && AVTOPIC="`mqtt_base_topic`/$4"
[ -n "$4" ] && [ "$4" = "true" ] && AVTOPIC="`mqtt_base_topic`"
echo -n {\""command_topic\"": \""${TOPIC}\"", \""state_topic\"": \""${TOPIC}\"", \""availability_topic\"": \""${AVTOPIC}\"", \""icon\"": \""mdi:$3\"", \""name\"": \""`mqtt_base_name "$2"`\"", \""unique_id\"": \""`mqtt_base_uniqueid $1`\"", \""device\"": `setup_device_base`}
}

setup_switch_opener_message(){
# unique_id, name, icon
TOPIC="`mqtt_base_topic`/door"
AVTOPIC="`mqtt_base_topic`"
echo -n {\""command_topic\"": \""${TOPIC}\"", \""state_topic\"": \""${TOPIC}\"", \""payload_on\"": \""online\"", \""payload_off\"": \""offline\"", \""availability_topic\"": \""${AVTOPIC}\"", \""icon\"": \""mdi:$3\"", \""name\"": \""`mqtt_base_name "$2"`\"", \""unique_id\"": \""`mqtt_base_uniqueid $1`\"", \""device\"": `setup_device_base`}
}

setup_device_automation_message(){
# type, subtype, payload
TOPIC="`mqtt_base_topic`/action"
echo -n {\""automation_type\"":\""trigger\"", \""type\"":\""button_${1}_press\"", \""subtype\"":\""button_$2\"", \""payload\"":\""$3\"", \""topic\"":\""${TOPIC}\"", \""device\"": `setup_device_base`}  
}

setup_binary_sensor_message(){
# topic, name, device_class, off_delay
TOPIC="`mqtt_base_topic`/$1"
AVTOPIC="`mqtt_base_topic`"
echo -n {\""state_topic\"": \""${TOPIC}\"", \""availability_topic\"": \""${AVTOPIC}\"", \""device_class\"": \""$3\"", \""off_delay\"": $4, \""name\"": \""`mqtt_base_name "$2"`\"", \""unique_id\"": \""`mqtt_base_uniqueid $1`\"", \""device\"": `setup_device_base`}
}

setup_sensor_message(){
# topic, name, device_class, icon
TOPIC="`mqtt_base_topic`/$1"
AVTOPIC="`mqtt_base_topic`"
echo -n {\""state_topic\"": \""${TOPIC}\"", \""availability_topic\"": \""${AVTOPIC}\"", \""device_class\"": \""$3\"", \""icon\"": \""mdi:$4\"", \""name\"": \""`mqtt_base_name "$2"`\"", \""unique_id\"": \""`mqtt_base_uniqueid $1`\"", \""device\"": `setup_device_base`}
}

mqtt_send(){ mosquitto_pub ${MQTT_OPTS} -t "${MTOPIC}" -m "${MDATA}"; }

for BTN in 1 2; do
  for CLK in short long quintuple; do
    MTOPIC=`setup_topic device_automation pb${BTN}_${CLK}`
    MDATA=`setup_device_automation_message ${CLK} ${BTN} pb${BTN}_${CLK}`
    mqtt_send
  done
done

MTOPIC=`setup_topic switch door`
MDATA=`setup_switch_message door/set "Door Relay" door door`
mqtt_send

MTOPIC=`setup_topic switch f1`
MDATA=`setup_switch_message f1 "F1 Button" keyboard-f1 true`
mqtt_send

MTOPIC=`setup_topic switch opener`
MDATA=`setup_switch_opener_message opener "Open Caller" phone`
mqtt_send

MTOPIC=`setup_topic binary_sensor ding`
MDATA=`setup_binary_sensor_message ding "Ding" occupancy 30`
mqtt_send

MTOPIC=`setup_topic sensor last_ding`
MDATA=`setup_sensor_message ding/last "Last Ding" timestamp history`
mqtt_send
