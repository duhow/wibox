#!/bin/sh

LOCKFILE=/tmp/heartbeat.lock
PIDFILE=/tmp/listener_mqtt.pid
log(){ echo "$*" | tee /dev/kmsg; }

WAIT=60
TIMEOUT=45

cd `dirname "$0"`
source ./mqtt_functions.sh
source /usr/bin/gpio.sh

TOPIC=`mqtt_base_topic`

STATUS=$(mosquitto_sub ${MQTT_OPTS} -I heartbeat -v -C 1 -t "${TOPIC}" -W ${TIMEOUT} | cut -d ' ' -f2)

if [ ! -f "$LOCKFILE" ] && [ "$STATUS" = "offline" ]; then
  STATUS=""
  log "Disconnected from MQTT. Rebooting in ${WAIT} seconds."
  wifi_led red
  sleep ${WAIT}
  reboot
elif [ -z "$STATUS" ] && [ -e "/proc/`cat ${PIDFILE}`" ]; then
  STATUS=online
elif [ "$STATUS" == "online" ] && [ ! -e "/proc/`cat ${PIDFILE}`" ]; then
  STATUS=offline
else
  STATUS=""
fi

if [ -n "$STATUS" ]; then
  log "Setting status as ${STATUS}"
  mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`" -m ${STATUS}
fi
