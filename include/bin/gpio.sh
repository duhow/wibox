#!/bin/sh

GPIOD=/sys/class/gpio

setup_gpio(){
  N=$1
  V=$2
  GPION=${GPIOD}/gpio${N}

  if [ ! -e "${GPION}" ]; then
    echo ${N} > ${GPIOD}/export
  fi
  
  DIRECTION=low
  [ "$V" == "1" ] && DIRECTION=high

  echo 0 > ${GPION}/active_low
  echo $DIRECTION > ${GPION}/direction
  echo $V > ${GPION}/value
}

setup_all_gpio(){
  setup_gpio 10 0
  setup_gpio 11 0
  setup_gpio 12 0
  setup_gpio 18 1
  setup_gpio 19 0
  setup_gpio 34 0
}

set_gpio(){ echo $2 > /sys/class/gpio/gpio$1/value; }

wifi_led() {
  [ "$1" == "red" ] && L=10
  [ "$1" == "green" ] && L=12
  [ "$1" == "blue" ] && L=11

  for LED in 10 11 12; do
    V=0
    [ "$LED" == "$L" ] && V=1
    set_gpio $LED $V
  done
}
