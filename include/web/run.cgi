#!/bin/sh

command=`echo "$QUERY_STRING" | awk '{split($0,array,"&")} END{print array[1]}' | awk '{split($0,array,"=")} END{print array[2]}'`

if [ "$command" = "open" ]; then
PLD=`echo "\xFB\x12\x01\x1E"`
fi
if [ "$command" = "dspy" ]; then
PLD=`echo "\xFB\x14\x01\x20"`
fi
if [ "$command" = "dspn" ]; then
PLD=`echo "\xFB\x14\x00\x1F"`
fi
if [ "$command" = "fone" ]; then
echo -e "\xFB\x17\x01\x23" > /dev/ttySGK1
sleep 3
echo -e "\xFB\x17\x00\x22" > /dev/ttySGK1
echo "Content-type: text/html" && echo ""
exit
fi
if [ "$command" = "guard" ]; then
PLD=`echo "\xFB\x15\x00\x20"`
fi

if [ "$command" = "unlock" ]; then
echo -e "\xFB\x14\x01\x20" > /dev/ttySGK1
sleep 3
echo -e "\xFB\x12\x01\x1E" > /dev/ttySGK1
sleep 1
echo -e "\xFB\x14\x00\x1F" > /dev/ttySGK1
echo "Content-type: text/html" && echo ""
exit
fi

if [ -z "$PLD" ]; then
echo "Status: 404 Not Found"
echo ""
exit
fi

echo -e $PLD > /dev/ttySGK1 && echo "Content-type: text/html" || echo "Status: 500 Internal Server Error"

# add empty body response
echo ""
