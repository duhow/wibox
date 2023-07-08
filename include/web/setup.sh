#!/bin/sh

WEBFOLDER=/var/www
SRCFOLDER=/usr/web
PIDFILE=/var/run/httpd.pid

mkdir -p ${WEBFOLDER}/cgi-bin

cp -fv ${SRCFOLDER}/index.html ${WEBFOLDER}
cp -fv ${SRCFOLDER}/run.cgi ${WEBFOLDER}/cgi-bin
ln -sf /mnt/mtd/alarm.log ${WEBFOLDER}/alarms

PORT=80

# if port 80 is in use, fallback to 81
netstat -ltn | grep -q ":${PORT} " && PORT=81

busybox httpd -p ${PORT} -h ${WEBFOLDER}

# create pid
ps | grep "busybox httpd" | grep -v grep | awk '{print $1}' > ${PIDFILE}
