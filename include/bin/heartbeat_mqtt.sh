#!/bin/sh

log(){ echo "$*" | tee /dev/kmsg; }

WAIT=60
TIMEOUT=45

cd `dirname "$0"`
source ./mqtt_functions.sh
source /usr/bin/gpio.sh

TOPIC=`mqtt_base_topic`

STATUS=$(mosquitto_sub ${MQTT_OPTS} -I heartbeat -v -C 1 -t "${TOPIC}" -W ${TIMEOUT} | cut -d ' ' -f2)

if [ "$STATUS" = "offline" ]; then
  log "Disconnected from MQTT. Rebooting in ${WAIT} seconds."
  wifi_led red
  sleep ${WAIT}
  reboot
fi
