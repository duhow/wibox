#!/bin/sh

cd `dirname "$0"`
source ./mqtt_functions.sh

WIFI_STATS=`wpa_cli -i wlan0 signal_poll`
RSSI=`echo ${WIFI_STATS} | grep RSSI | cut -d '=' -f2 | cut -d ' ' -f1`

# mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/wifi" -m "${RSSI}"

# ----

JSON_STR="{"
for line in ${WIFI_STATS}; do
  data_key=`echo $line | cut -d '=' -f1`
  data_value=`echo $line | cut -d '=' -f2`
  JSON_STR="${JSON_STR}\""${data_key}\"":\""${data_value}\"","
done

# remove last comma and close list
JSON_STR="${JSON_STR%?}}"

# if no valid data, exit
echo "${JSON_STR}" | grep -q RSSI || exit 1

mosquitto_pub ${MQTT_OPTS} -t "`mqtt_base_topic`/wifi/stats" -m "${JSON_STR}"
