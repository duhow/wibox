#!/bin/sh

# If temp, Start Sofia for few seconds to initialize hardware and stop
# Otherwise, close the rest of intercom services and start Sofia only.


if echo "$0" | grep -q -E temp; then
  IS_TEMP=1
fi

if [ -z "${IS_TEMP}" ]; then
  /usr/bin/listener.sh stop
  kill `cat /var/run/httpd.pid`
  killall udhcpc wpa_supplicant crond
fi

if [ -n "${IS_TEMP}" ]; then
  insmod /ko/extdrv/goke_wdt.ko soft_noboot=1 nowayout=1
else
  insmod /ko/extdrv/goke_wdt.ko
fi

ln -s /etc/sensors/nvp6134_hw.bin /tmp/sensor_hw.bin
cp /usr/Sofia.lzma /var
cd /var; tar -x --lzma -f Sofia.lzma
rm -f /var/Sofia.lzma

cp -f /usr/cloud/states /var/cloud/states

echo 3 > /proc/sys/vm/drop_caches

if [ -f "/etc/TZ" ]; then
  mv /etc/TZ /etc/TZ.tmp
fi

if [ -n "${IS_TEMP}" ]; then
  timeout -t 35 /usr/bin/system_sofia &
  timeout -t 30 /var/Sofia
else
  /usr/bin/system_sofia &
  /var/Sofia
fi
rmmod goke_wdt
rm -f /var/Sofia
killall ntsclientcon_goke_static

if [ -f "/etc/TZ.tmp" ]; then
  mv /etc/TZ.tmp /etc/TZ
fi
