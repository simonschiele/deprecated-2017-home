#!/bin/bash
hook_name=setup_gobi2000-umts
hook_systemtypes="laptop"
hook_optional=true
hook_version=0.0

mkdir modem/
cd modem/

apt-get install gobi-loader

wget http://metashell.de/mirror/arch/aur/gobi-firmware/gobi-firmware.zip
unzip gobi-firmware.zip

mkdir -p /lib/firmware/gobi/

cp UMTS/amss.mbn /lib/firmware/gobi/
cp UMTS/apps.mbn /lib/firmware/gobi/
cp 6/UQCN.mbn /lib/firmware/gobi/

