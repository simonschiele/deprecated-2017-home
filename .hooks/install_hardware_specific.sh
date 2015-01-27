#!/bin/bash
hook_name=skel
hook_version=0.1
hook_systemtypes="minimal server workstation laptop"    # optional, default: empty
hook_optional=false                                     # optional, default: true
hook_once=true                                          # optional, default: true
hook_sudo=true                                          # optional, default: true
hook_hostnames="cstation cpad simon-work"               # optional, default: ""
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( grep -q -i 'intel.*core.*i[357]' /proc/cpuinfo ) ; then
    echo "Installing 'Intel Core i3/i5/i7' specific packages'"
    apt-get install -y i7z
fi

if ( grep -q -i -e wlan -e wifi <( dmesg ) <( lspci -v ) <( lsusb -v ) ) ; then
    echo "Setting up wlan adapter"
    apt-get install -y wireless-tools 
fi

if ( lsusb -vvv 2>/dev/null | grep -q -i 'qual.*gobi.*2000' ) ; then
    echo "Installing driver for 'Qualcomm Gobi 2000 GSM/UMTS/3G'"
   
    // replace with tmp.$$ folder
    if ( ! rm -rf /unpack-modem/modem 2>/dev/null ) ; then
        echo "> ERROR: Could not remove old '/unpack-modem/modem' build-folder"
        exit 1
    fi

    mkdir -p /tmp/unpack-modem/
    cd /tmp/unpack-modem/

    if ( ! is_installed gobi-loader ) ; then
        sudo apt-get install gobi-loader
    fi

    if [[ -e /share/Software/Firmware/gobi-firmware.tar.gz ]] && ( tar xzf /share/Software/Firmware/gobi-firmware.tar.gz ) ; then
        echo "Successfully unpacked from /share/Software/Firmware/gobi-firmware.tar.gz"
        sudo mkdir -p /lib/firmware/gobi/
        sudo cp amss.mbn apps.mbn UQCN.mbn /lib/firmware/gobi/
    elif ( wget http://metashell.de/mirror/arch/aur/gobi-firmware/gobi-firmware.zip ) && ( unzip gobi-firmware.zip ) ; then
        echo "Successfully downloaded and unpacked from http://metashell.de/mirror/arch/aur/gobi-firmware/gobi-firmware.zip"
        sudo mkdir -p /lib/firmware/gobi/
        sudo cp UMTS/amss.mbn /lib/firmware/gobi/
        sudo cp UMTS/apps.mbn /lib/firmware/gobi/
        sudo cp 6/UQCN.mbn /lib/firmware/gobi/
    else
        echo "> ERROR: Could not download (or unpack) gobi-firmware.zip"
        success=false
    fi

    cd $OLDPWD
fi



