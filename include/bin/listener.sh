#!/bin/sh

INTERCOM_DEVICE=/dev/ttySGK1
INPUT_FILE=/tmp/input_cmd
ALARM_FILE=/mnt/mtd/alarm.log
CODES_FILE=/usr/wibox_codes.txt
PIDFILE=/tmp/listener.pid
PIDFILE_MQTT=/tmp/listener_mqtt.pid
CRONFILE=/var/spool/cron/crontabs/root
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

# change workdir to script dir
cd `dirname "$0"`
source /usr/bin/gpio.sh

if [ "$1" = "stop" ]; then
  if [ ! -f "${PIDFILE}" ] || [ ! -e "/proc/`cat ${PIDFILE}`" ]; then
    log "Listener was not running!"
    exit 0
  fi
  kill `cat ${PIDFILE}` && rm -f ${PIDFILE} || log "Cannot close listener"
  kill `cat ${PIDFILE_MQTT}` && rm -f ${PIDFILE_MQTT} || log "Cannot close listener MQTT"
  killall -q head mosquitto_pub mosquitto_sub
  wifi_led off
  # remove mqtt cron checks
  sed -i '/mqtt_wifi_stats/d' ${CRONFILE}
  sed -i '/heartbeat_mqtt/d' ${CRONFILE}
  if pgrep crond >/dev/null; then
    killall crond
    crond -b
  fi
  exit 0
fi

# Check running once
if [ -f "${PIDFILE}" ]; then
  if [ -e "/proc/`cat ${PIDFILE}`" ]; then
    log "Listener is already running! Closing."
    exit 0
  else
    log "Listener was running and closed!"
    for NAME in head; do
      killall ${NAME} 2>/dev/null
    done
  fi
fi
echo "$$" > ${PIDFILE}

log "Starting listener"

which mosquitto_pub >/dev/null 2&>/dev/null
if [ "$?" = 0 ]; then
  source ./mqtt_functions.sh
  mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m init
  if [ "$?" = 0 ]; then
    MQTT_ENABLED=1
    log "MQTT enabled"
    ./listener_mqtt.sh &
    (sleep 6 && pgrep mosquitto_sub >/dev/null && mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m config) &
  else
    if [ "${MQTT_MUST_RUN}" = "1" ]; then
      log "MQTT exited with error $? and must run - will reboot"
      wifi_led red
      sleep 60
      reboot
    else
      log "MQTT exited with error $? - skipping"
    fi
  fi
fi

while true; do
  head -c 4 ${INTERCOM_DEVICE} > ${INPUT_FILE}

  log "Code get is `reverse_code`"
  if [ ! -f "$INPUT_FILE" ]; then
    log "Command is empty"
  elif is_code CMD_RESET; then
    log "Factory rebooting"
    wifi_led red
    touch /mnt/mtd/factory
    sync
    killall mosquitto_sub
    reboot
  elif is_code START_CALL; then
    log "Intercom opened"
    if [ -n "${MQTT_ENABLED}" ]; then
      if [ -f "${PIDFILE_MQTT}" ] && [ -e "/proc/`cat ${PIDFILE_MQTT}`" ]; then
        mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m online
        touch /tmp/intercom_opened
      fi
      mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/door" -m online
    fi
    if [ -n "${CALL_OPEN_DOOR}" ]; then
      log "Opening door"
      sleep 0.5
      get_code TRANSFER_CMD_UNLOCK_DOOR > ${INTERCOM_DEVICE}
      sleep 1
      get_code STOP_CALL > ${INTERCOM_DEVICE}
      [ -f "/tmp/open_once" ] && rm -f /tmp/open_once

      if [ -n "${MQTT_ENABLED}" ]; then
        mqtt_ding OFF
        mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/door" -m offline
      fi
      CALL_OPEN_DOOR=""
    fi
  elif is_code ALARM_REPORT; then
    log "Alarm reported, calling at door"
    if [ -n "${MQTT_ENABLED}" ]; then
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
  elif is_code HANG_UP_0; then
    log "Call missed"
    if [ -n "${MQTT_ENABLED}" ]; then
      mqtt_ding OFF
      mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/door" -m offline
    fi
    report_alarm 2
  elif is_code CMD_STOP_RING; then
    log "Phone was picked up, stop alarm"
    [ -n "${MQTT_ENABLED}" ] && mqtt_ding OFF
    report_alarm 3
  elif is_code PUSH_STATE_0; then
    if [ -n "${MQTT_ENABLED}" ]; then
      mosquitto_pub -r ${MQTT_OPTS} -t "`mqtt_base_topic`/forward" -m OFF
    fi
  elif is_code PUSH_STATE_1; then
    if [ -n "${MQTT_ENABLED}" ]; then
      mosquitto_pub -r ${MQTT_OPTS} -t "`mqtt_base_topic`/forward" -m ON
    fi
  fi

  mv ${INPUT_FILE} ${INPUT_FILE}.prev

done
