#!/bin/sh

PATH=/sbin:/bin:/usr/bin:/usr/sbin:$PATH

if [ `uname` = Linux ]; then
mount |  awk '{print $3}' | grep -i "${1}$" | head -1 | awk '{print $NF}'
elif [ `uname` = "HP-UX" ]; then
mount |  awk '{print $1}' | grep -i "${1}$" | head -1 | awk '{print $NF}'
elif [ `uname` = "SunOS" ]; then
mount |  awk '{print $1}' | grep -i "${1}$" | head -1 | awk '{print $NF}'
elif [ `uname` = "AIX" ]; then
mount |  awk '{print $2}' | grep -i "${1}$" | head -1 | awk '{print $NF}'
fi

