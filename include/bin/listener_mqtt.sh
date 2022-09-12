#!/bin/sh

INTERCOM_DEVICE=/dev/ttySGK1
PIDFILE=/tmp/listener_mqtt.pid
CODES_FILE=/usr/wibox_codes.txt
CRONFILE=/var/spool/cron/crontabs/root
WIFISTATS_CRON_MIN=2

log(){ echo "$*" | tee /dev/kmsg; }
get_code(){ echo -e $(grep "^$1 " ${CODES_FILE} | cut -d' ' -f2-); }
reverse_code(){ 
  CODE=$(od -t x1 < ${INPUT_FILE} | head -n1 | cut -d' ' -f2- | tr [:lower:] [:upper:] | sed 's/^/\\\\x/' | sed 's/ /\\\\x/g')
  CODEGET=$(grep " ${CODE}" ${CODES_FILE} | cut -d' ' -f1)
  [ -z "${CODEGET}" ] && CODEGET="unknown - ${CODE}"
  echo ${CODEGET}
}

# Check running once
if [ -f "${PIDFILE}" ]; then
  if [ -e "/proc/`cat ${PIDFILE}`" ]; then
    log "Listener is already running! Closing."
    exit 0
  else
    log "Listener was running and closed!"
    for NAME in mosquitto_sub; do
      killall ${NAME} 2>/dev/null
    done
  fi
fi
echo "$$" > ${PIDFILE}

source ./mqtt_functions.sh
log "Starting MQTT listener"

TOPIC=`mqtt_base_topic`

mosquitto_sub -v -R --will-topic ${TOPIC} --will-payload offline --will-retain ${MQTT_OPTS} -t "${TOPIC}" -t "${TOPIC}/#" | while read -r line; do
  val=$(echo "$line" | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
  case $line in
    "${TOPIC}/door/set"*)
      if [ "$val" = "ON" ] || [ "$val" = "PRESS" ]; then
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
      elif [ "$val" = "PRESS" ]; then
        get_code START_F1 > ${INTERCOM_DEVICE}
        sleep 3
        get_code STOP_F1 > ${INTERCOM_DEVICE}
      fi
    ;;
    "${TOPIC} "*)
      if [ "$val" = "ONLINE" ]; then
        log "Connected successfully, configuring Home Assistant MQTT device"
        ./mqtt_config_homeassistant.sh
        if ! grep -q "mqtt_wifi_stats.sh" ${CRONFILE}; then
          log "Configuring wifi stats reporter and restarting cron"
          echo "*/${WIFISTATS_CRON_MIN} * * * * /usr/bin/mqtt_wifi_stats.sh" >> ${CRONFILE}
          killall crond
          crond -b
        fi

      elif [ "$val" = "OFFLINE" ]; then
        log "Disconnected from MQTT. Rebooting in 60 seconds."
        sleep 60
        reboot
      fi
    ;;
  esac
done

log "MQTT listener stopped"
