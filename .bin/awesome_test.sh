#!/bin/sh
Xephyr -ac -br -noreset -screen 800x600 :1 &
sleep 2 
DISPLAY=:1.0 awesome 
