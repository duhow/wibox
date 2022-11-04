#!/bin/sh

[ -f "/mnt/mtd/passwd" ] && mount --bind /mnt/mtd/passwd /etc/passwd
[ -f "/mnt/mtd/factory" ] && ( /usr/run-orig.sh; exit )
[ -f "/mnt/mtd/TZ" ] && export TZ=$(cat /mnt/mtd/TZ)

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
ifconfig eth0 up
ifconfig eth0 192.168.1.10

telnetd &

# copy etc as writable
cp -Rdpf /etc /var/etc
mount --bind /var/etc /etc

for P in /usr /mnt/mtd ; do
if [ -e "${P}/etc" ]; then
  cp -Rdpf ${P}/etc/* /etc
fi
done

if command -v dropbear >/dev/null; then
  dropbear -R

  if [ "$?" = 0 ]; then
    echo "dropbear enabled"
    killall telnetd
  fi
fi

mkdir -p /var/lock /var/run /var/fat32_0 /var/cloud
cp -f /usr/cloud/states /var/cloud/states

for FILE in hal hw_crypto media audio sensor i2s; do
  insmod /ko/${FILE}.ko
done

for FILE in wifi_pow rtl8188fu bit1628a rtc8563; do
  insmod /ko/extdrv/${FILE}.ko
done

sleep 1
mdev -s

# update hostname, read config line 4 straight to the UDID
UDID=$(dd if=/dev/mtdblock6 skip=324 count=12 bs=1 2>/dev/null)
[ -z "${UDID}" ] && UDID="000000000000"
echo "IDS7938${UDID:8:4}" > /proc/sys/kernel/hostname

#web
cd /usr/web && ./setup.sh

#wifi
mkdir /var/wifi
cp /usr/sbin/wifi_conf/* /var/wifi/
cp /usr/sbin/hostapd.conf /var/wifi

rm -rf /var/run/wpa_supplicant
mkdir -p /var/run/wpa_supplicant

WPA_CONF="/var/wifi/wpa_supplicant.conf"
[ -f "/mnt/mtd/wpa_supplicant.conf" ] && WPA_CONF="/mnt/mtd/wpa_supplicant.conf"

ln -s /mnt/mtd/Config/resolv.conf /var/resolv.conf
wpa_supplicant -i wlan0 -c ${WPA_CONF} -B
udhcpc -i wlan0 -s /var/wifi/udhcpc.conf

# increase network buffer
echo 1084576 > /proc/sys/net/core/rmem_max
echo 1084576 > /proc/sys/net/core/wmem_max

echo 3 > /proc/sys/vm/drop_caches; free

# cron
CRONTABS="/var/spool/cron/crontabs"
mkdir -p ${CRONTABS}
cat << EOF >> ${CRONTABS}/root
15 3 * * 6 reboot
*/10 * * * * /usr/bin/heartbeat.sh
0 * * * * ntpd -q -p pool.ntp.org
* * * * * dmesg -c | grep -v RTL871X >> /var/messages
EOF
if [ -f "/mnt/mtd/crontab" ]; then
  cat /mnt/mtd/crontab >> ${CRONTABS}/root
fi
crond -b

/usr/bin/listener.sh &

[ -f "/mnt/mtd/post.sh" ] && /mnt/mtd/post.sh
