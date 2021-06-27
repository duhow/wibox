#!/bin/sh

while read data; do
  codename=$(echo "CODE_${data}" | cut -d' ' -f1)
  codevalue=$(echo "${data}" | cut -d' ' -f2- | sed 's/ /\\x/g')
  codevalue=$(echo -e "\xFB\x${codevalue}")
  export ${codename}="${codevalue}"
done << EOF
ALARM_REPORT 11 00 1C
CMD_STOP_RING 23 00 2E
HANG_UP 13 00 1E
CUART_START 10 04 1F
MCU_STATE_0 16 00 21
MCU_STATE_1 16 01 22
PUSH_STATE_0 19 00 24
PUSH_STATE_1 19 01 25
SET_MODE_2 10 00 1B
CMD_DOWN_LONG_1 24 01 30
CMD_DOWN_LONG_2 24 02 31
CMD_RESET 20 00 2B
STA_TO_AP 21 00 2C
CALL_GUARD 15 00 20
CALL_GUARD_ERROR_2 15 03 23
START_CALL 14 01 20
TRANSFER_CMD_UNLOCK_DOOR 12 01 1E
STOP_CALL 14 00 1F
START_F1 17 01 23
STOP_F1 17 00 22
EOF
