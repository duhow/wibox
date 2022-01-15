#!/bin/sh

FILE=include/bin/ipctool
FILE_DOWNLOAD=https://github.com/OpenIPC/ipctool/releases/download/latest/ipctool

if [ ! -d "include/" ]; then
  echo "[*] Folder include does not exist, skipping."
  exit
fi

if [ -e "${FILE}" ]; then
  echo "[*] ipctool already downloaded."
  exit
fi

echo "[*] Downloading ipctool"
if command -v curl >/dev/null ; then
  curl -Lo ${FILE} ${FILE_DOWNLOAD}
else
  wget -o ${FILE} ${FILE_DOWNLOAD}
fi

chmod 755 ${FILE}
