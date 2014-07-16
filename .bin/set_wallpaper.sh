#!/bin/bash

aspectRatios="4:3 5:4 16:9 16:10"
resolutions3="320x240 640x480 800x600 1024x768 1280x960 1400x1050 1440x1080 1600x1200"
resolutions4="1280x1024"
resolutions9="1920x1080 1280x720 1600x900 2048x1152 2560x1440"
resolutions10="2560x1600 1920x1200 1680x1050 1440x900 1280x800"

LANG=C
DISPLAY=${DISPLAY:-:0}
backgroundDir=~/.backgrounds

debug=false
scaling=false
splitWallpaper=false
multihead=false
multiheadMultipleResolutions=false

printHelp() {
    echo "set_wallpaper.sh"
    echo ""
    echo "-h    - This help text"
    echo "-d    - Debug/Verbose mode"
    echo "-r    - rename files in backgrounds-dir (puts resolution in title)"
    echo ""
    exit 0
}

renameFiles() {
    if [ -z "$( which identify )" ]
    then
        echo "Error: ImageMagick/identify not found. Please install ImageMagick for resolution detection + rename feature." >&2
        exit 1
    fi

    find "${backgroundDir}" -type f -not -path "*/.git*" | grep -v "[0-9]\{3,5\}x[0-9]\{3,5\}" | while read img
    do
        res=$( identify "$img" | awk {'print $3'} )
        target=$( echo "$img" | sed "s|\.\([A-Za-z]\{3,4\}\)$|_$res\.\1|g" )
        mv -v "$img" "$target"
    done
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
fi

# detect resolution
for screen in $( xrandr -d ${DISPLAY} -q | grep " connected" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' )
do
    screens=$(( ${screens:-0} + 1 ))
    res=$( echo ${screen} | grep -o '^[0-9]\{3,4\}x[0-9]\{3,4\}' )
    pos=$( echo ${screen} | cut -f'2' -d'+' )
done
resolution=$( xrandr -d ${DISPLAY} -q | grep current | sed 's|^.*current\ \([0-9]\{3,4\}\)\ x\ \([0-9]\{3,4\}\).*$|\1x\2|g' )

# detect display / usable resolutions
[ ${screens} -gt 1 ] && multihead=true

if ( ${multihead} )
then
    nativeResolution=
    for res in $( xrandr -d ${DISPLAY} -q | grep -i "\ connected" | grep -o '[0-9]\{3,4\}x[0-9]\{3,4\}' | sort -u )
    do
        [ -z "$nativeResolution" ] && nativeResolution=${res}
        if [ "${res}" != "${nativeResolution}" ]
        then
            multiheadMultipleResolutions=true
        fi
        usableResolutions="${usableResolutions} ${res}"
    done
else
    nativeResolution=$resolution
fi

# detect aspectRatio
res1=$( echo $nativeResolution | cut -f'1' -d'x')
res2=$( echo $nativeResolution | cut -f'2' -d'x')
for aspectRatio in $aspectRatios
do
    ar1=$( echo $aspectRatio | cut -f'1' -d':' )
    ar2=$( echo $aspectRatio | cut -f'2' -d':' )

    if [ "$(( $res1 / $ar1 ))" == "$(( $res2 / $ar2))" ]
    then
        break
    fi
done

# load usable resolutions for aspectRatio
usableResolutions=$( eval echo \$resolutions$ar2 )

# find compatible wallpapers
for res in ${usableResolutions}
do
    for file in $( find ${backgroundDir} -type f -iname "*${res}*" ! -iname "*left*" ! -iname "*right*" ! -iname "*both*" )
    do
        wallpapers="${wallpapers}${file}\n"
    done
done

if ( ${multihead} )
then
    for file in $( find ${backgroundDir} -type f -iname "*${resolution}*both*" -or -iname "*${nativeResolution}*left*" )
    do
        wallpapers="${wallpapers}${file}\n"
        wallpapers="${wallpapers}${file}\n"
    done
fi
( ${debug} ) && echo "> compatible wallpapers:"
( ${debug} ) && echo -e "${wallpapers}" | sed '/^\ *$/d' | sed 's|^|\t|g'

# choose random wallpaper
wallpaper=$( echo -e "${wallpapers}" | sed '/^\ *$/d' | shuf -n 1 )
wallpaperResolution=$( echo "$wallpaper" | grep -o "[0-9]\{3,4\}x[0-9]\{3,4\}" )
[ "${wallpaperResolution}" != "${resolution}" ] && scaling=true

if ( echo "${wallpaper}" | grep -q "left" )
then
    splitWallpaper=true
    wallpaper="${wallpaper} ${wallpaper/left/right}"
fi

# output debug
( ${debug} ) && echo "> backgroundDir: ${backgroundDir}"
( ${debug} ) && echo "> screens: ${screens}"
( ${debug} ) && echo "> resolution: ${resolution}"
( ${debug} ) && echo "> native resolution: ${nativeResolution}"
( ${debug} ) && echo "> usable resolutions: ${usableResolutions}"
( ${debug} ) && echo "> aspect ratio: ${aspectRatio}"
( ${debug} ) && echo "> multihead: ${multihead}"
( ${debug} ) && echo "> multiple resolutions: ${multiheadMultipleResolutions}"
( ${debug} ) && echo "> selected wallpaper: ${wallpaper}"
( ${debug} ) && echo "> split wallpaper: ${splitWallpaper}"
( ${debug} ) && echo "> needs scaling: ${scaling}"

if ( ${scaling} )
then
    fehParams="--bg-scale"
elif ( ${multihead} )
then
    fehParams="--bg-tile"
else
    fehParams="--bg-center"
fi

# trigger feh
if [ -n "$( which feh )" ]
then
    cmd="feh ${fehParams}"
else
    echo -e "Error: No tool found to set wallpaper. Install one of the supported tools:\n\t* feh\n'" >&2
    exit 1
fi

DISPLAY="${DISPLAY}" ${cmd} ${wallpaper}

