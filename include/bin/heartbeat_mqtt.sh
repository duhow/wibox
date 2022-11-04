#!/bin/sh

log(){ echo "$*" | tee /dev/kmsg; }

WAIT=60

cd `dirname "$0"`
source ./mqtt_functions.sh

TOPIC=`mqtt_base_topic`

STATUS=$(mosquitto_sub ${MQTT_OPTS} -I heartbeat -v -C 1 -t "${TOPIC}" | cut -d ' ' -f2)

if [ "$STATUS" = "offline" ]; then
  log "Disconnected from MQTT. Rebooting in ${WAIT} seconds."
  sleep ${WAIT}
  reboot
fi
