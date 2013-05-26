#!/bin/bash

res="800x600"

clear
echo "> $( date ) - starting test"

echo -n "> killing old Xephyr..."
killall -9 Xephyr 2>/dev/null 
echo -e "\t\t[done]"

echo -n "> starting Xephyr X Server (resolution 800x600)"
Xephyr -terminate -ac -br -keybd ephyr,,,xkbmodel=pc105,xkblayout=de,xkbrules=evdev,xkboption=grp:alts_toogle -noreset -screen 800x600 :1.0 &
echo -e "\t\t[done]"

echo "> starting awesome..."
sleep 2 
DISPLAY=:1.0 awesome 

echo -n "> killing Xephyr..."
killall -9 Xephyr 2>/dev/null 
echo -e "\t\t[done]"


