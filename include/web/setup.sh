#!/bin/sh

WEBFOLDER=/var/www
SRCFOLDER=/usr/web

mkdir -p ${WEBFOLDER}/cgi-bin

cp -fv ${SRCFOLDER}/index.html ${WEBFOLDER}
cp -fv ${SRCFOLDER}/run.cgi ${WEBFOLDER}/cgi-bin

PORT=80

# if port 80 is in use, fallback to 81
netstat -ltn | grep -q ":${PORT} " && PORT=81

busybox httpd -p ${PORT} -h ${WEBFOLDER}
