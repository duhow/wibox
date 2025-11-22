#!/bin/sh

LOCKFILE=/tmp/heartbeat.lock
PIDFILE=/tmp/listener_mqtt.pid
LOGFILE=/var/log/mqtt_heartbeat.log

# Create log directory if it doesn't exist
mkdir -p /var/log

log(){
  MSG="[$(date)] $*"
  echo "$MSG" | tee /dev/kmsg
  echo "$MSG" >> $LOGFILE 2>/dev/null
}

WAIT=60
TIMEOUT=30  # Reduced from 45 to 30 seconds for faster response

# Change to /usr/bin where mqtt_functions.sh is located
cd /usr/bin
source ./mqtt_functions.sh
source /usr/bin/gpio.sh 2>/dev/null || true

TOPIC=`mqtt_base_topic`

log "Starting heartbeat check for topic: ${TOPIC}"

# Check basic connectivity before MQTT check
if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
  log "ERROR: No internet connectivity"
  wifi_led red 2>/dev/null || true
  exit 1
fi

# Check MQTT broker connection with unique client ID
STATUS=$(mosquitto_sub ${MQTT_OPTS} -I heartbeat_$(date +%s) -v -C 1 -t "${TOPIC}" -W ${TIMEOUT} 2>/dev/null | cut -d ' ' -f2)
MQTT_EXIT_CODE=$?

log "MQTT check result: STATUS='${STATUS}', EXIT_CODE=${MQTT_EXIT_CODE}"

# Check if listener_mqtt process is running
LISTENER_RUNNING=false
if [ -f "$PIDFILE" ]; then
  LISTENER_PID=$(cat $PIDFILE)
  if [ -e "/proc/${LISTENER_PID}" ]; then
    LISTENER_RUNNING=true
    log "Listener MQTT running with PID: ${LISTENER_PID}"
  else
    log "WARNING: Listener MQTT PID file exists but process not running"
  fi
else
  log "WARNING: No listener MQTT PID file found"
fi

# Determine action based on state
if [ ! -f "$LOCKFILE" ] && [ "$STATUS" = "offline" ]; then
  log "CRITICAL: Device reported as offline. Preparing for reboot in ${WAIT} seconds."
  wifi_led red 2>/dev/null || true
  sleep ${WAIT}
  log "REBOOT: Rebooting due to MQTT offline status"
  reboot
elif [ -z "$STATUS" ] && [ "$LISTENER_RUNNING" = "true" ]; then
  STATUS=online
  log "No MQTT response but listener running - assuming online"
elif [ "$STATUS" = "online" ] && [ "$LISTENER_RUNNING" = "false" ]; then
  STATUS=offline
  log "WARNING: MQTT says online but listener not running - marking offline"
elif [ -z "$STATUS" ] && [ "$MQTT_EXIT_CODE" != "0" ]; then
  log "WARNING: Unable to connect to MQTT broker (exit code: ${MQTT_EXIT_CODE})"
  # Don't change status if we can't connect
  STATUS=""
fi

# Publish status if determined
if [ -n "$STATUS" ]; then
  log "Publishing status: ${STATUS}"
  # Publish to main topic without retain (used for events/commands)
  mosquitto_pub ${MQTT_OPTS} -t "${TOPIC}" -m ${STATUS}
  # Publish to availability topic with retain (HA best practice for availability)
  mosquitto_pub ${MQTT_OPTS} -t "${TOPIC}/availability" -m ${STATUS} -r
  
  # Set LED status
  if [ "$STATUS" = "online" ]; then
    wifi_led blue 2>/dev/null || wifi_led green 2>/dev/null || true
  fi
else
  log "No status change determined"
fi

log "Heartbeat check completed"
