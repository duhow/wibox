#!/bin/sh

INTERCOM_DEVICE=/dev/ttySGK1
CODES_FILE=/usr/wibox_codes.txt

log(){ echo "$*" | tee /dev/kmsg; }
get_code(){ echo -e $(grep "^$1 " ${CODES_FILE} | cut -d' ' -f2-); }
reverse_code(){ 
  CODE=$(od -t x1 < ${INPUT_FILE} | head -n1 | cut -d' ' -f2- | tr [:lower:] [:upper:] | sed 's/^/\\\\x/' | sed 's/ /\\\\x/g')
  CODEGET=$(grep " ${CODE}" ${CODES_FILE} | cut -d' ' -f1)
  [ -z "${CODEGET}" ] && CODEGET="unknown - ${CODE}"
  echo ${CODEGET}
}

source ./mqtt_functions.sh
log "Starting MQTT listener"

TOPIC=`mqtt_base_topic`

mosquitto_sub -v -R --will-topic ${TOPIC} --will-payload offline --will-retain ${MQTT_OPTS} -t "${TOPIC}/#" | while read -r line; do
  val=$(echo "$line" | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
  case $line in
    "${TOPIC}/door/set"*)
      if [ "$val" = "ON" ]; then
        log "MQTT Open door"
        get_code TRANSFER_CMD_UNLOCK_DOOR > ${INTERCOM_DEVICE}
        (sleep 1 && mosquitto_pub ${MQTT_OPTS} -t "${TOPIC}/door/set" -m OFF) &
      fi
    ;;
    "${TOPIC}/door"*)
      log "MQTT Door $val"
      if [ "$val" = "ON" ] || [ "$val" = "ONLINE" ]; then
        get_code START_CALL > ${INTERCOM_DEVICE}
      elif [ "$val" = "OFF" ] || [ "$val" = "OFFLINE" ]; then
        get_code STOP_CALL > ${INTERCOM_DEVICE}
      fi
    ;;
    "${TOPIC}/f1"*)
      log "MQTT F1 Button $val"
      if [ "$val" = "ON" ]; then
        get_code START_F1 > ${INTERCOM_DEVICE}
      elif [ "$val" = "OFF" ]; then
        get_code STOP_F1 > ${INTERCOM_DEVICE}
      fi
    ;;
  esac
done
