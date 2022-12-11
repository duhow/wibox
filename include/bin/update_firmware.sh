#!/bin/sh

DATAPART=/dev/mtdblock4
BLOCK=4096

MAXSIZE=11534336
UPDATE_FILE=/tmp/update.img

if [ ! -f "${UPDATE_FILE}" ]; then
  echo "[!] Update file not found, exiting."
  exit 1
fi

UPDATE_SIZE=$(stat -c "%s" ${UPDATE_FILE})
if [ "$UPDATE_SIZE" -ge "$MAXSIZE" ]; then
  echo "[!] Update file exceeds size - ${UPDATE_SIZE}, cannot flash!"
  exit 1
fi

# stop heartbeat check while upgrading
touch /tmp/heartbeat.lock

COUNT="$(( ${UPDATE_SIZE} / ${BLOCK} ))"
echo "[*] Checking current content - ${COUNT}"
PRE_UPDATE_HASH=$(dd if=${DATAPART} bs=${BLOCK} count=${COUNT} | md5sum - | cut -d' ' -f1)
echo "[*] Hash is ${PRE_UPDATE_HASH}"

echo "[*] Hashing update"
UPDATE_HASH=$(md5sum ${UPDATE_FILE} | cut -d' ' -f1)
echo "[*] Hash is ${UPDATE_HASH}"

echo "[*] Lazy umounting filesystem"
umount -l ${DATAPART} || ( echo "[!] Error while umounting, cancelling!"; exit 2 )

echo "[*] Flashing update"
dd if=${UPDATE_FILE} of=${DATAPART} bs=${BLOCK}
sync
fsync ${DATAPART}

echo "[*] Checking current content - ${COUNT}"
POST_UPDATE_HASH=$(dd if=${DATAPART} bs=${BLOCK} count=${COUNT} | md5sum - | cut -d' ' -f1)
echo "[*] Hash is ${POST_UPDATE_HASH}"

if [ "${POST_UPDATE_HASH}" = "${UPDATE_HASH}" ]; then
  echo "[*] Hash matches, all good!"
  exit 0
else
  echo "[!] Hash does not match! Please check!"
  exit 3
fi
