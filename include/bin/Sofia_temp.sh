#!/bin/sh

# Start Sofia for few seconds to initialize hardware and stop

insmod /ko/extdrv/goke_wdt.ko soft_noboot=1 nowayout=1

ln -s /etc/sensors/nvp6134_hw.bin /tmp/sensor_hw.bin
cp /usr/Sofia.lzma /var
cd /var; tar -x --lzma -f Sofia.lzma
rm -f /var/Sofia.lzma

timeout -t 30 /var/Sofia
rmmod goke_wdt
rm -f /var/Sofia
