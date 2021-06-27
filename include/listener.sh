#!/bin/sh

INTERCOM_DEVICE=/dev/ttySGK1
INPUT_FILE=/tmp/input_cmd
ALARM_FILE=/mnt/mtd/alarm.log
CODES_FILE=/usr/wibox_codes.txt

log(){ echo "$*" | tee /dev/kmsg; }
report_alarm(){ echo "$(date +%s),$1" >> $ALARM_FILE; }
get_code(){ echo -e $(grep "^$1 " ${CODES_FILE} | cut -d' ' -f2-); }
is_code(){ [ "`cat ${INPUT_FILE}`" = "`get_code $1`" ]; }
reverse_code(){ 
  CODE=$(od -t x1 < ${INPUT_FILE} | head -n1 | cut -d' ' -f2- | tr [:lower:] [:upper:] | sed 's/^/\\x/' | sed 's/ /\\x/g')
  grep " ${CODE}" ${CODES_FILE} | cut -d' ' -f1
}

open_door(){
  log "Opening door"
  get_code START_CALL > ${INTERCOM_DEVICE}
  sleep 1
  get_code TRANSFER_CMD_UNLOCK_DOOR > ${INTERCOM_DEVICE}
  sleep 1
  get_code STOP_CALL > ${INTERCOM_DEVICE}
}

log "Starting listener"

while true; do
  head -c 4 ${INTERCOM_DEVICE} > ${INPUT_FILE}

  if [ ! -f "$INPUT_FILE" ]; then
    log "Command is empty"
  elif is_code CMD_RESET; then
    log "Factory rebooting"
    touch /mnt/mtd/factory
    sync
    reboot
  elif is_code ALARM_REPORT; then
    log "Alarm reported, calling at door"
    if [ -f "/tmp/open_once" ] || [ -f "/tmp/open_door" ]; then
      log "Automatic open"
      report_alarm 4
      [ -f "/tmp/open_once" ] && rm -f /tmp/open_once
      open_door
    else
      report_alarm 1
    fi
  elif is_code HANG_UP; then
    log "Call missed"
    report_alarm 2
  elif is_code CMD_STOP_RING; then
    log "Phone was picked up, stop alarm"
    report_alarm 3
  fi

done
