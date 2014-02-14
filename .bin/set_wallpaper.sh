#!/bin/bash

resolutions="128x160 132x50 140x192 160x120 160x128 160x144 160x200 240x160 320x200 320x240 384x256 432x240 480x272 480x320 512x342 512x384 640x200 640x256 640x350 640x400 640x480 720x348 720x350 720x364 720x400 720x480 800x480 800x600 832x624 854x480 960x720 1024x576 1024x768 1056x400 1152x864 1152x870 1152x900 1280x1024 1280x720 1280x768 1280x800 1360x1024 1360x768 1366x768 1366x900 1400x1050 1440x900 1600x1200 1600x900 1680x1050 1680x945 1920x1080 1920x1200 2048x1080 2048x1152 2048x1536 2560x1440 2560x1600 2560x2048 2880x1800 3200x2048 3200x2400 3840x2160 3840x2400 4096x2160 4096x3072 5120x3200 5120x4096 6400x4096 6400x4800 7680x4320 7680x4800"
aspect_ratios="4:3 16:9 16:10"

LANG=C
DISPLAY=${DISPLAY:-:0}
backgroundDir=~/.backgrounds

debug=false
multihead=false
scaling=false

printHelp() {
    echo "set_wallpaper.sh"
    echo ""
    echo "-h    - This help text"
    echo "-d    - Debug/Verbose mode"
    echo "-s    - scale other resolutions that are aspect-ratio compatible"
    echo ""
}

gcd() {
    # Greatest common divisor function - from advanced bash scripting guide (Example 8-1)
    dividend=$1             #  Arbitrary assignment.
    divisor=$2              #! It doesn't matter which of the two is larger.
    remainder=1             #  If an uninitialized variable is used inside
                            #+ test brackets, an error message results.
    until [ "$remainder" -eq 0 ]
    do
        let "remainder = $dividend % $divisor"
        dividend=$divisor     # Now repeat with 2 smallest numbers.
        divisor=$remainder
    done                      # Euclid's algorithm

    echo $dividend
}

if ( echo "$@" | grep -q -e "\-d" )
then
    debug=true
fi

if ( echo "$@" | grep -q -e "\-s" )
then
    scaling=true
fi

if ( echo "$@" | grep -q -e "\-h" )
then
    printHelp
    exit 0
fi

for screen in $( xrandr -q | grep " connected" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' )
do
    screens=$(( ${screens:-0} + 1 ))
    res=$( echo ${screen} | grep -o '^[0-9]\{3,4\}x[0-9]\{3,4\}' )
    pos=$( echo ${screen} | cut -f'2' -d'+' )
done
resolution=$( xrandr -q | grep current | sed 's|^.*current\ \([0-9]\{3,4\}\)\ x\ \([0-9]\{3,4\}\).*$|\1x\2|g' )
usableResolutions=${resolution}

if [[ ${screens} > 1 ]]
then
    ( ${debug} ) && echo "> Multihead detected"
    multihead=true
fi
( ${debug} ) && echo "> screens: $screens"
( ${debug} ) && echo "> resolution: ${resolution}"

if ( ${multihead} )
then
    for res in $( xrandr -q | grep -i "\ connected" | grep -o '[0-9]\{3,4\}x[0-9]\{3,4\}' | sort -u )
    do
        echo -n
        usableResolutions="${usableResolutions} ${res}"
    done
    
    if ( ${scaling} )
    then
        echo "> scaling: not implemented yet"
    fi
fi

( ${debug} ) && echo "> usable resolutions: ${usableResolutions}"

resolution_or=$( echo ${usableResolutions} | sed -e 's| |" -e "|g' -e 's|$|"|g' -e 's|^|-e "|g' )
for res in ${usableResolutions}
do
    for file in $( find ${backgroundDir} -type f -iname "*${res}*" ! -iname "*left*" ! -iname "*right*" )
    do
        wallpapers="${wallpapers}${file}\n"
    done
done
( ${debug} ) && echo "> wallpapers:"
( ${debug} ) && echo -e "${wallpapers}" | sed '/^\ *$/d' | sed 's|^|\t|g'

wallpaper=$( echo -e "${wallpapers}" | sed '/^\ *$/d' | shuf -n 1 )
( ${debug} ) && echo "> wallpaper: ${wallpaper}"

if ! ( feh --bg-tile ${wallpaper} )
then
    exit 1
fi
exit 0

