#!/bin/bash

DISPLAY=${DISPLAY:-:0}
resolutions="128x160 132x50 140x192 160x120 160x128 160x144 160x200 240x160 320x200 320x240 384x256 432x240 480x272 480x320 512x342 512x384 640x200 640x256 640x350 640x400 640x480 720x348 720x350 720x364 720x400 720x480 800x480 800x600 832x624 854x480 960x720 1024x576 1024x768 1056x400 1152x864 1152x870 1152x900 1280x1024 1280x720 1280x768 1280x800 1360x1024 1360x768 1366x768 1366x900 1400x1050 1440x900 1600x1200 1600x900 1680x1050 1680x945 1920x1080 1920x1200 2048x1080 2048x1152 2048x1536 2560x1440 2560x1600 2560x2048 2880x1800 3200x2048 3200x2400 3840x2160 3840x2400 4096x2160 4096x3072 5120x3200 5120x4096 6400x4096 6400x4800 7680x4320 7680x4800"



for screen in $( xrandr -q | grep " connected" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' )
do
    screens=$(( ${screens:-0} + 1 ))
    res=$( echo ${screen} | grep -o '^[0-9]\{3,4\}x[0-9]\{3,4\}' )
    pos=$( echo ${screen} | cut -f'2' -d'+' )
done
resolution=$( xrandr -q | grep current | sed 's|^.*current\ \([0-9]\{3,4\}\)\ x\ \([0-9]\{3,4\}\).*$|\1x\2|g' )

if [[ $screens == 2 ]] && [[ $(( RANDOM % 2 )) > 0 ]] ; then
    wallpaper=$( find ~/.backgrounds/ -iname "*${res}*left*" | sort -R | head -n 1 )
    wallpaper="${wallpaper} ${wallpaper/left/right}"
else
    wallpaper_single=$( find ~/.backgrounds/ -iname "*${res}*" | grep -v "left\|right" | sort -R | head -n 1 )
    while [[ ${i} -lt ${screens} ]] ; do
        wallpaper="${wallpaper_single} ${wallpaper}"
        i=$(( $i + 1 ))
    done
fi

echo "screens: $screens"
echo "all res: $resolution"
echo "wallpaper: $wallpaper"


feh --bg-center ${wallpaper}

