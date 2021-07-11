#!/bin/sh

which mosquitto_pub >/dev/null 2&>/dev/null 
if [ "$?" != 0 ]; then 
  echo "[*] Mosquitto binary not found, cannot use."
  exit 1
fi

MQTT_HOST=127.0.0.1
MQTT_USER=""
MQTT_PASS=""
MQTT_HOMEASSISTANT="homeassistant"
MQTT_CONFIG_STORE="/mnt/mtd/mqtt.conf"
MQTT_CONFIG_FILE="/tmp/mqtt.conf"

[ ! -f "${MQTT_CONFIG_FILE}" ] && [ -f "${MQTT_CONFIG_STORE}" ] && cp ${MQTT_CONFIG_STORE} ${MQTT_CONFIG_FILE}
[ -f "${MQTT_CONFIG_FILE}" ] && export $(cat ${MQTT_CONFIG_FILE} | xargs)

MODEL=$(hostname)
[ "$MODEL" = "localhost" ] && MODEL="IDS79380000"

MQTT_OPTS="-I wibox_${MODEL}"
[ -n "${MQTT_HOST}" ] && MQTT_OPTS="${MQTT_OPTS} -h ${MQTT_HOST}"
[ -n "${MQTT_USER}" ] && MQTT_OPTS="${MQTT_OPTS} -u ${MQTT_USER}"
[ -n "${MQTT_PASS}" ] && MQTT_OPTS="${MQTT_OPTS} -P ${MQTT_PASS}"

