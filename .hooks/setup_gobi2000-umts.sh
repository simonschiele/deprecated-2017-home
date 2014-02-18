#!/bin/bash
hook_name=setup_gobi2000-umts
hook_systemtypes="laptop"
hook_optional=false
hook_version=0.3
hook_hostnames="cpad"
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

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

