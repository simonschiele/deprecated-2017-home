#!/bin/bash
hook_name=install_nvidia
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

URL="http://www.nvidia.de/content/DriverDownload-March2009/confirmation.php?url=/XFree86/Linux-x86/304.43/NVIDIA-Linux-x86-304.43.run&lang=de&type=GeForce"
FILENAME="/usr/src/nvidia_304-43.sh"

if ! ( lspci | grep -iq "vga.*nvidia" )
then
    echo "No NVIDIDA vga card found. Skipping '${hook_name}' hook."
    exit 1
fi

wget -O- ${FILENAME} "${URL}"

chmod +x ${FILENAME}
${FILENAME} 

