#!/bin/sh

set -e

PACKAGE_NAME=dropbear
PACKAGE_VERSION=2020.81
PACKAGE_DOWNLOAD=https://matt.ucc.asn.au/dropbear/releases/dropbear-${PACKAGE_VERSION}.tar.bz2
IMAGE_BUILDER=ghcr.io/duhow/wibox-crosstool:latest
FILE=include/sbin/dropbear

if [ ! -d "include/" ]; then
  echo "[*] Folder include does not exist, skipping."
  exit
fi

if [ -e "${FILE}" ]; then
  echo "[*] ${PACKAGE_NAME} already build, skipping."
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

echo "[*] Downloading ${PACKAGE_NAME} ${PACKAGE_VERSION}"
if command -v curl >/dev/null ; then
  curl -Lo ${PACKAGE_DOWNLOAD##*/} ${PACKAGE_DOWNLOAD}
else
  wget -N -o ${PACKAGE_DOWNLOAD##*/} ${PACKAGE_DOWNLOAD}
fi

mkdir -p ${PACKAGE_NAME}
tar xf ${PACKAGE_DOWNLOAD##*/} -C ${PACKAGE_NAME} --strip-components=1

echo "[*] Applying build patch"

sed -i 's!/etc/dropbear!/mnt/mtd/dropbear!g' ${PACKAGE_NAME}/default_options.h
sed -i 's!DO_MOTD 1!DO_MOTD 0!' ${PACKAGE_NAME}/default_options.h

echo "[*] Building ${PACKAGE_NAME}"
${DOCKER} run --rm -it -v $PWD/${PACKAGE_NAME}:/src -w /src --entrypoint /bin/bash ${IMAGE_BUILDER} -c '
 ./configure --enable-static --disable-zlib --disable-lastlog \
   --host=arm-goke-linux-uclibcgnueabi --target=arm-goke-linux-uclibcgnueabi;
 make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1'

if [ ! -e "${PACKAGE_NAME}/dropbearmulti" ]; then
  echo "[!] Build failed!"
  exit 1
fi

echo "[*] Installing binaries"

mkdir -p include/sbin
cp -vf ${PACKAGE_NAME}/dropbearmulti include/sbin

for NAME in dropbear dropbearkey dropbearconvert; do
  ln -svf dropbearmulti include/sbin/${NAME}
done

for NAME in dbclient scp; do
  ln -svf ../sbin/dropbearmulti include/bin/${NAME}
done

echo "[*] Cleaning up build"
rm -rf ${PACKAGE_NAME} ${PACKAGE_DOWNLOAD##*/}
