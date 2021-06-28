#!/bin/sh

command=`echo "$QUERY_STRING" | awk '{split($0,array,"&")} END{print array[1]}' | awk '{split($0,array,"=")} END{print array[2]}'`

_send(){ echo -e "$1" > /dev/ttySGK1 || echo "Status: 500 Internal Server Error"; }
func_open(){ _send "\xFB\x12\x01\x1E"; }
func_dspy(){ _send "\xFB\x14\x01\x20"; }
func_dspn(){ _send "\xFB\x14\x00\x1F"; }
func_fone(){ _send "\xFB\x17\x01\x23"; sleep 3; _send "\xFB\x17\x00\x22"; }
func_guard(){ _send "\xFB\x15\x00\x20"; }

func_unlock(){ func_dspy; sleep 2; func_open; sleep 1; func_dspn; }

if func_${command}; then
  echo "Content-type: text/html"
else
  echo "Status: 404 Not Found"
fi

# add empty body response
echo ""
