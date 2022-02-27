#!/bin/sh

set -e

PACKAGE_VERSION=v2.0.14
PACKAGE_DOWNLOAD=https://github.com/eclipse/mosquitto/archive/refs/tags/${PACKAGE_VERSION}.tar.gz
IMAGE_BUILDER=ghcr.io/duhow/wibox-crosstool:latest
FILE=include/bin/mosquitto_sub

if [ ! -d "include/" ]; then
  echo "[*] Folder include does not exist, skipping."
  exit
fi

if [ -e "${FILE}" ]; then
  echo "[*] mosquitto already build, skipping."
  exit
fi

# select proper command
for COMMAND in docker podman; do
  if command -v ${COMMAND} >/dev/null ; then
    DOCKER=${COMMAND}
    break
  fi
done

echo "[*] Downloading crosstool-NG toolchain"
${DOCKER} pull ${IMAGE_BUILDER}

echo "[*] Downloading mosquitto ${PACKAGE_VERSION}"
if command -v curl >/dev/null ; then
  curl -Lo mosquitto.tar.gz ${PACKAGE_DOWNLOAD}
else
  wget -N -o mosquitto.tar.gz ${PACKAGE_DOWNLOAD}
fi

mkdir -p mosquitto
tar xf mosquitto.tar.gz -C mosquitto --strip-components=1

echo "[*] Applying build patch"

cat << EOF > mosquitto/mosquitto.patch
--- a/lib/dummypthread.h	2021-06-09 16:06:23.000000000 +0200
+++ b/lib/dummypthread.h	2021-12-30 11:56:21.898242877 +0100
@@ -4,7 +4,7 @@
 #define pthread_create(A, B, C, D)
 #define pthread_join(A, B)
 #define pthread_cancel(A)
-#define pthread_testcancel()
+#define pthread_testcancel(void)
 
 #define pthread_mutex_init(A, B)
 #define pthread_mutex_destroy(A)
EOF

patch -p1 -d mosquitto < mosquitto/mosquitto.patch

echo "[*] Building mosquitto"
${DOCKER} run --rm -it -v $PWD/mosquitto:/src -w /src ${IMAGE_BUILDER} \
  make WITH_THREADING=no WITH_TLS=no WITH_CJSON=no WITH_BRIDGE=no WITH_PERSISTENCE=no \
     WITH_MEMORY_TRACKING=no WITH_DOCS=no WITH_STRIP=yes WITH_STATIC_LIBRARIES=yes \
     WITH_SHARED_LIBRARIES=no CFLAGS="-Wall -Os" CROSS_COMPILE=arm-goke-linux-uclibcgnueabi-

if [ ! -e "mosquitto/client/mosquitto_sub" ]; then
  echo "[!] Build failed!"
  exit 1
fi

for NAME in mosquitto_sub mosquitto_pub; do
  cp -vf mosquitto/client/${NAME} include/bin/${NAME}
done

echo "[*] Cleaning up build"
rm -rf mosquitto mosquitto.tar.gz
