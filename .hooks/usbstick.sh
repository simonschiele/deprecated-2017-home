#!/bin/bash
#
# Simple tool to create/update usb bootstick
#
# Depends: json_xs, TickTick
# you also need a '~/.stick.json' config file to generate/update your stick. 
#

###################################################################
# Example stick.json:
#
# {
#    "name" = "Simons Bootstick"
#    "keep_images" = false,
#    "dir_tmp" = "/mnt/stick/",
#    "extras" = {
#        "freedos" = True,
#        "memtest" = True
#    },
#    "sources" = [
#        {
#            name="grml96",
#            desc="grml (multiarch)"
#            url="http://download.grml.org/grml96-full_2012.05.iso"
#            checksum="sha1:9e13a1c822926640e6e090f2f221364919e99fa7"
#            enabled=True
#        },
#        {
#            name="backtrack32",
#            desc="BackTrack Linux – Penetration Testing Distribution (KDE, 32bit)"
#            url="http://ftp.halifax.rwth-aachen.de/backtrack/BT5R3-KDE-32.iso"
#            checksum="md5:d324687fb891e695089745d461268576"
#            enabled=True
#        },
#        {
#            name="backtrack64",
#            desc="BackTrack Linux – Penetration Testing Distribution (KDE, 64bit)"
#            url="http://ftp.halifax.rwth-aachen.de/backtrack/BT5R3-KDE-64.iso"
#            checksum="md5:981b897b7fdf34fb1431ba84fe93249f"
#            enabled=True
#        }
#    ]
# }
#
#
###################################################################

# Devel settings
SCRIPTNAME="usbstick.sh"

VERBOSE=false
DRYRUN=false

CONFIG="${HOME}/.stick.json"

JSON_LIB="${HOME}/.lib/TickTick/ticktick.sh"
JSON_TOOL="json_xs"
JSON_VALIDATE="json_xs -t null"

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
NORMAL="\e[00m"

STATUS=true
###################################################################

# {{{ functions: helper

exitclean() {
    echo 
    cd ${OLDPWD}
    exit ${1}
}

message() {
    if [ -z "${1}" ]
    then
        echo -ne ">>> "
    elif [ "${1}" == "info" ] || [ "${1}" == "status" ]
    then
        echo -ne "[${YELLOW}${1}${NORMAL}] "
        shift 
    elif [ "${1}" == "error" ] || [ "${1}" == "fail" ]
    then
        echo -ne "[${RED}${1}${NORMAL}] "
        shift 
    else
        echo -ne "[${1}] "
        shift 
    fi
    echo "${@}"
}

helpmessage() {
    echo -e ""
    echo -e "${SCRIPTNAME} - tool to generate/update a universal rescue stick"
    echo -e ""
    echo -e "-h\t\thelp (this message)"
    echo -e "-t\t\tdryrun (don't do anything)"
    echo -e "-v\t\tverbose"
    echo -e ""
}

indented() {
    ${@} | sed 's|^|\t|g'
}

list_devices() {
    udisks --dump | grep device-file | sed 's|^.*\:\ *\(.*\)|\1|g' | while read dev ; do if ( udisks --show-info ${dev} | grep -q "removable.*1" ) ; then echo ${dev} ; fi ; done
}

# }}}

# {{{ Check Params

# -t | testmode
if ( echo ${@} | grep -q "\-h" )
then
    helpmessage
    exitclean 0
fi

# -v | verbose
if ( echo ${@} | grep -q "\-v" )
then
    VERBOSE=true
fi

# -t | testmode
if ( echo ${@} | grep -q "\-t" )
then
    DRYRUN=true
fi

# }}}

# {{{ Check Depends
if ! [ -r "${JSON_LIB}" ]
then 
    message error "depends '${JSON_LIB}' not found"
    SUCCESS=false
else
    source ${JSON_LIB}
fi

if ! [ -r ${CONFIG} ]
then
    message error "config file '${CONFIG}' not found"
    SUCCESS=false
fi

if [ -z $( which ${JSON_TOOL} ) ]
then 
    message error "depends '${JSON_TOOL}' not found"
    SUCCESS=false
else
    if [ -r ${CONFIG} ] && ! ( ${JSON_VALIDATE} < ${CONFIG} )
    then
        message error "config file '${CONFIG}' is invalid"
        SUCCESS=false
    fi
fi

if ! ( ${SUCCESS} )
then
    exitclean 1
else
    echo -e "\n${GREEN}${SCRIPTNAME}${NORMAL} - simple bootstick tool\n"
fi

# }}}

# {{{ Get Config / Sources

# }}}

# {{{ Check existing sticks

if ( $VERBOSE )
then
    devices=$( list_devices )
    message info "Available devices:"
    if [ -z "$devices" ]
    then
        echo -e "\tNone"
    else
        indented echo ${devices}
    fi
fi

# }}}

# {{{ Verify / Download sources

# }}}

# {{{ Install / Update Images

# }}}

# {{{ Install / Update Extras

# }}}

# {{{ Install / Update bootloader

# }}}

exitclean `${SUCCESS}`

