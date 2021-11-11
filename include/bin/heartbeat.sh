#!/bin/sh

LOCKFILE=/tmp/heartbeat.lock
ADDR_ICMP="8.8.8.8"
ADDR_DNS="www.google.com"
ATTEMPTS=10
DELAY=20

test_icmp(){ ping -4 -q -W 3 -c 1 $1; }
test_dns(){ nslookup $1; }
clear_lock(){ rm -f ${LOCKFILE} 2>/dev/null; }
get_gateway_ip(){ ip route | grep "default via" | grep "dev wlan0" | cut -d ' ' -f3; }

# lock for 30 minutes
if [ "`find ${LOCKFILE} -mmin -30` 2>/dev/null" = "${LOCKFILE}" ] ; then
  echo "Already running! Exiting."
  exit 0
fi

clear_lock
touch ${LOCKFILE}

# Add router / gateway IP address
ADDR_ICMP="${ADDR_ICMP} `get_gateway_ip`"

echo "Starting to check connectivity"

while [ "$ATTEMPTS" -gt 0 ]; do
  ATTEMPTS="$(( ATTEMPTS - 1 ))"

  for ADDR in ${ADDR_ICMP}; do
    if test_icmp ${ADDR}; then
      echo "ICMP check succeeded!"
      clear_lock
      exit 0
    else
      echo "ICMP check failed!"
    fi
  done

  if test_dns ${ADDR_DNS}; then
    echo "DNS check succeeded!"
    clear_lock
    exit 0
  else
    echo "DNS check failed!"
  fi

  if [ "$ATTEMPTS" -gt 0 ]; then
    echo "Waiting for next retry"
    sleep ${DELAY}
  fi
done

echo "Healthcheck failed! Rebooting."
reboot
