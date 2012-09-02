#!/bin/bash

# check my own checksum against online file
update_available() {
    URL="${1:-'http://simon.psaux.de/git/home.git/plain/.bin/usbstick.sh'}"
    FILE="${2:-${0}}"
    REMOTE_CHECKSUM=$( wget -q -O- "${URL}" | md5sum | awk {'print $1'} )
    LOCAL_CHECKSUM=$( md5sum "${FILE}" | awk {'print $1'} )
    if [ ${REMOTE_CHECKSUM} != ${LOCAL_CHECKSUM} ]
    then
        return 0
    else
        return 1 
    fi
}

