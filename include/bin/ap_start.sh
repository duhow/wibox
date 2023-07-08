#!/bin/sh

WIFI_CONF=/var/wifi
HOSTAPD_CONF=${WIFI_CONF}/hostapd.conf
UDHCPD_CONF=${WIFI_CONF}/udhcpd.conf

for NAME in hostapd udhcpc udhcpd go.sh wpa_supplicant; do
  killall -q -9 ${NAME}
done

ifconfig wlan0 down

UDID=$(dd if=/dev/mtdblock6 skip=324 count=12 bs=1 2>/dev/null)
if [ -z "$UDID" ]; then UDID=tdks00000000; fi

# CHANGEME
PASSWORD=$UDID

sed -ri "s/(ssid=).*/\1$UDID/" ${HOSTAPD_CONF}
sed -ri "s/(wpa_passphrase=).*/\1$PASSWORD/" ${HOSTAPD_CONF}

insmod /ko/extdrv/rtl8188fu.ko

ifconfig wlan0 up
ifconfig wlan0 192.168.111.1

hostapd -d -B -P /var/run/hostapd.pid ${HOSTAPD_CONF}
udhcpd ${UDHCPD_CONF}
