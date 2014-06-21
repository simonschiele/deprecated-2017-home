#!/bin/bash

aspectRatios="4:3 5:4 16:9 16:10"
resolutions3="640x480 800x600 1024x768 1400x1050 1440x1080 1600x1200"
resolutions4="1280x1024"
resolutions9="1920x1080 1280x720"
resolutions10="1920x1200 1280x800"

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
    echo "-r    - rescan/rename files in backgrounds-dir"
    echo "-s    - scale other resolutions that are aspect-ratio compatible"
    echo ""
    exit 0
}

renameFiles() {
    echo "not implemented"
    exit 1
}

if ( echo "$@" | grep -q -e "\-r" )
then
    renameFiles
elif ( echo "$@" | grep -q -e "\-h" )
then
    printHelp
else
    if ( echo "$@" | grep -q -e "\-d" )
    then
        debug=true
    fi

    if ( echo "$@" | grep -q -e "\-s" )
    then
        scaling=true
    fi
fi

# detect resolution
for screen in $( xrandr -d ${DISPLAY} -q | grep " connected" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' )
do
    screens=$(( ${screens:-0} + 1 ))
    res=$( echo ${screen} | grep -o '^[0-9]\{3,4\}x[0-9]\{3,4\}' )
    pos=$( echo ${screen} | cut -f'2' -d'+' )
done
resolution=$( xrandr -d ${DISPLAY} -q | grep current | sed 's|^.*current\ \([0-9]\{3,4\}\)\ x\ \([0-9]\{3,4\}\).*$|\1x\2|g' )
res1=$( echo $resolution | cut -f'1' -d'x')
res2=$( echo $resolution | cut -f'2' -d'x')

# detect aspectRatio
for aspectRatio in $aspectRatios
do
    ar1=$( echo $aspectRatio | cut -f'1' -d':' )
    ar2=$( echo $aspectRatio | cut -f'2' -d':' )

    if [ "$(( $res1 / $ar1 ))" == "$(( $res2 / $ar2))" ]
    then
        break
    fi
done
usableResolutions=$( eval echo \$resolutions$ar2 )

# debug output
if [[ ${screens} > 1 ]]
then
    ( ${debug} ) && echo "> Multihead detected"
    multihead=true
fi

( ${debug} ) && echo "> screens: $screens"
( ${debug} ) && echo "> resolution: ${resolution}"
( ${debug} ) && echo "> aspect ratio: ${aspect_ratio}"

# display
if ( ${multihead} )
then
    for res in $( xrandr -d ${DISPLAY} -q | grep -i "\ connected" | grep -o '[0-9]\{3,4\}x[0-9]\{3,4\}' | sort -u )
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
    for file in $( find ${backgroundDir} -type f -iname "*${res}*" ! -iname "*left*" ! -iname "*right*" ! -iname "*both*" )
    do
        wallpapers="${wallpapers}${file}\n"
    done
done
( ${debug} ) && echo "> wallpapers:"
( ${debug} ) && echo -e "${wallpapers}" | sed '/^\ *$/d' | sed 's|^|\t|g'

# choose random wallpaper
wallpaper=$( echo -e "${wallpapers}" | sed '/^\ *$/d' | shuf -n 1 )
( ${debug} ) && echo "> wallpaper: ${wallpaper}"


# 
if ( ${multihead} )
then
    feh_param="--bg-scale"
else
    feh_param="--bg-tile"
fi

DISPLAY="${DISPLAY}" feh ${feh_param} ${wallpaper}

