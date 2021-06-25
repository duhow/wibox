#!/bin/sh
mkdir -p /var/www/cgi-bin

cp index.html /var/www
cp run.cgi /var/www/cgi-bin

busybox httpd -p 81 -h /var/www
