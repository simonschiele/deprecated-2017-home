#!/bin/bash
#
# easybox_keygen.sh (c) 2012 GPLv3
#
# www.wotan.cc
# 

if [ -n "$2" ] || [ -z "$1" ]
then
    echo "wlan_pass.sh <mac>"
    exit 1
fi

MAC=$1

# Take the last 2 Bytes of the MAC-Address (0B:EC), and convert it to decimal.

take5=${MAC:12}
last4=${take5/:/}

# Fill up to 4 places with zeros, if necessary:
deci=($(printf "%04d" "0x$last4" | sed 's/.*\(....\)/\1/;s/./& /g'))
#
# The digits M9 to M12 are just the last digits (9.-12.) of the MAC:
hexi=($(echo ${MAC:12:5} | sed 's/://;s/./& /g'))
# K1 = last byte of (d0 + d1 + h2 + h3)
# K2 = last byte of (h0 + h1 + d2 + d3)
c1=$(printf "%d + %d + %d + %d" ${deci[0]} ${deci[1]} 0x${hexi[2]} 0x${hexi[3]})
c2=$(printf "%d + %d + %d + %d" 0x${hexi[0]} 0x${hexi[1]} ${deci[2]} ${deci[3]})
K1=$((($c1)%16))
K2=$((($c2)%16))
X1=$((K1^${deci[3]}))
X2=$((K1^${deci[2]}))
X3=$((K1^${deci[1]}))
Y1=$((K2^0x${hexi[1]}))
Y2=$((K2^0x${hexi[2]}))
Y3=$((K2^0x${hexi[3]}))
Z1=$((0x${hexi[2]}^${deci[3]}))
Z2=$((0x${hexi[3]}^${deci[2]}))
Z3=$((K1^K2))
printf "EasyBox WPA: %x%x%x%x%x%x%x%x%x\n" $X1 $Y1 $Z1 $X2 $Y2 $Z2 $X3 $Y3 $Z3 | tr a-f A-F

