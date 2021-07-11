#!/bin/sh

INTERCOM_DEVICE=/dev/ttySGK1
INPUT_FILE=/tmp/input_cmd
ALARM_FILE=/mnt/mtd/alarm.log
CODES_FILE=/usr/wibox_codes.txt
MQTT_ENABLED=""
CALL_OPEN_DOOR=""

log(){ echo "$*" | tee /dev/kmsg; }
report_alarm(){ echo "$(date +%s),$1" >> $ALARM_FILE; }
get_code(){ echo -e $(grep "^$1 " ${CODES_FILE} | cut -d' ' -f2-); }
is_code(){ [ "`cat ${INPUT_FILE}`" = "`get_code $1`" ]; }
reverse_code(){ 
  CODE=$(od -t x1 < ${INPUT_FILE} | head -n1 | cut -d' ' -f2- | tr [:lower:] [:upper:] | sed 's/^/\\\\x/' | sed 's/ /\\\\x/g')
  CODEGET=$(grep " ${CODE}" ${CODES_FILE} | cut -d' ' -f1)
  [ -z "${CODEGET}" ] && CODEGET="unknown - ${CODE}"
  echo ${CODEGET}
}

mqtt_ding(){ mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/ding" -m $1 & }

log "Starting listener"

which mosquitto_pub >/dev/null 2&>/dev/null
if [ "$?" = 0 ]; then
  source ./mqtt_functions.sh
  mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m init
  if [ "$?" = 0 ]; then
    MQTT_ENABLED=1
    log "MQTT enabled"
    ./listener_mqtt.sh &
    (sleep 6 && pgrep mosquitto_sub >/dev/null && mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m online) &
  else
    log "MQTT error $? - skipping"
  fi
fi

while true; do
  head -c 4 ${INTERCOM_DEVICE} > ${INPUT_FILE}

  log "Code get is `reverse_code`"
  if [ ! -f "$INPUT_FILE" ]; then
    log "Command is empty"
  elif is_code CMD_RESET; then
    log "Factory rebooting"
    touch /mnt/mtd/factory
    sync
    killall mosquitto_sub
    reboot
  elif is_code START_CALL; then
    log "Intercom opened"
    if [ -n "${ENABLE_MQTT}" ]; then
      mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/door" -m online
    fi
    if [ -n "${CALL_OPEN_DOOR}" ]; then
      log "Opening door"
      sleep 0.5
      get_code TRANSFER_CMD_UNLOCK_DOOR > ${INTERCOM_DEVICE}
      sleep 1
      get_code STOP_CALL > ${INTERCOM_DEVICE}
      [ -f "/tmp/open_once" ] && rm -f /tmp/open_once

      if [ -n "${ENABLE_MQTT}" ]; then
        mqtt_ding OFF
        mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/door" -m offline
      fi
      CALL_OPEN_DOOR=""
    fi
  elif is_code ALARM_REPORT; then
    log "Alarm reported, calling at door"
    if [ -n "${ENABLE_MQTT}" ]; then
      mqtt_ding ON
      mosquitto_pub -r ${MQTT_OPTS} -t "`mqtt_base_topic`/ding/last" -m "$(date -Iseconds)" &
    fi
    if [ -f "/tmp/open_once" ] || [ -f "/tmp/open_door" ]; then
      log "Automatic open"
      report_alarm 4
      CALL_OPEN_DOOR=1
      get_code START_CALL > ${INTERCOM_DEVICE}
    else
      report_alarm 1
    fi
  elif is_code HANG_UP; then
    log "Call missed"
    [ -n "${ENABLE_MQTT}" ] && mqtt_ding OFF
    report_alarm 2
  elif is_code CMD_STOP_RING; then
    log "Phone was picked up, stop alarm"
    [ -n "${ENABLE_MQTT}" ] && mqtt_ding OFF
    report_alarm 3
  fi

  mv ${INPUT_FILE} ${INPUT_FILE}.prev

done
