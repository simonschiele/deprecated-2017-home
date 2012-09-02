#!/bin/bash
#
# Simple tool to create/update usb bootstick
#
# Depends: parted
#

###################################################################

VERBOSE=false

CONFIG_IMAGES_DIR="/home/simon"
CONFIG_IMAGES_KEEP=true

CONFIG_ENABLE_GRML96=true
CONFIG_ENABLE_BT32=false
CONFIG_ENABLE_BT64=false

CONFIG_EXTRAS_FREEDOS=true
CONFIG_EXTRAS_MEMTEST=true

###################################################################

SOURCE_GRML96_NAME="grml96"
SOURCE_GRML96_DESC="grml (multiarch)"
SOURCE_GRML96_URL="http://download.grml.org/grml96-full_2012.05.iso"
SOURCE_GRML96_CHECKSUM="sha1:9e13a1c822926640e6e090f2f221364919e99fa7"
SOURCE_GRML96_UPDATEVERSION=1

SOURCE_BT32_NAME="backtrack32"
SOURCE_BT32_DESC="BackTrack Linux – Penetration Testing Distribution (KDE, 32bit)"
SOURCE_BT32_URL="http://ftp.halifax.rwth-aachen.de/backtrack/BT5R3-KDE-32.iso"
SOURCE_BT32_CHECKSUM="md5:d324687fb891e695089745d461268576"
SOURCE_BT32_UPDATEVERSION=1

SOURCE_BT64_NAME="backtrack64"
SOURCE_BT64_DESC="BackTrack Linux – Penetration Testing Distribution (KDE, 64bit)"
SOURCE_BT64_URL="http://ftp.halifax.rwth-aachen.de/backtrack/BT5R3-KDE-64.iso"
SOURCE_BT64_CHECKSUM="md5:981b897b7fdf34fb1431ba84fe93249f"
SOURCE_BT64_UPDATEVERSION=1

###################################################################

SCRIPTNAME="usbstick.sh"
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

message_verbose() {
    if ( $VERBOSE )
    then
        message "${1}" "${2}"
    fi
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
    echo -e "-v\t\tverbose"
    echo -e ""
}

indented() {
    ${@} | sed 's|^|\t|g'
}

cleanup() {
    
    sync ${DEV} >/dev/null 2>&1 
    sleep 1

    if ( mountpoint ${DIR}/mnt/ >/dev/null )
    then
        message_verbose info "Unmounting stick '${DIR}/mnt/'"
        umount ${DIR}/mnt/
    fi
    
    if ( mountpoint ${DIR}/iso/ >/dev/null )
    then
        message_verbose info "Unmounting iso '${DIR}/iso/'"
        umount ${DIR}/iso/
    fi
    
    if [ -n "${DIR}" ]
    then
        message_verbose info "Removing temporary dir '${DIR}'"
        rm -rf "${DIR}"
    fi

}

get_size() {
    parted -m -l | grep "^${@}" | cut -f'2' -d':'
}

get_partitions() {
    dev=$( basename ${@} )
    grep ${dev} /proc/partitions | awk {'print $4'} | grep -v "${dev}$" 
} 

get_label() {
    /sbin/blkid ${@} | sed 's|.*LABEL="\([A-Za-z0-9\/]*\)".*$|\1|g'
}

list_devices_pretty() {
    udisks --dump | grep device-file | sed 's|^.*\:\ *\(.*\)|\1|g' | while read dev ; do if ( udisks --show-info ${dev} | grep -q "removable.*1" ) ; then echo "${dev} ($( get_size ${dev} ))" ; fi ; done
}

list_devices() {
    udisks --dump | grep device-file | sed 's|^.*\:\ *\(.*\)|\1|g' | while read dev ; do if ( udisks --show-info ${dev} | grep -q "removable.*1" ) ; then echo "${dev}" ; fi ; done
}

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

check_checksum() {
    checksumstr="${1}"
    file="${2}"
        
    checksumtype=$( echo ${checksumstr} | cut -f'1' -d':' )
    checksum=$( echo ${checksumstr} | cut -f'2' -d':' )
        
    if [ "${checksumtype}" == "sha1" ] 
    then
        if [ "${checksum}" != "$( sha1sum ${file} | awk {'print $1'} )" ]
        then
            valid=false
        fi
    elif [ "${checksumtype}" == "md5" ]
    then
        if [ "${checksum}" != "$( md5sum ${file} | awk {'print $1'} )" ]
        then
            valid=false
        fi
    else
        message "error" "Unknown checksum type"
        exitclean 1
    fi

    if ( $valid )
    then
        return 0
    else
        return 1 
    fi
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

if ! [ $( id -u ) -eq 0 ]
then
    message error "Please run as sudo/root"
    exitclean 1
fi

if [ -z $( which parted ) ]
then 
    message error "depends 'parted' not found"
    SUCCESS=false
fi

if ! ( ${SUCCESS} )
then
    exitclean 1
else
    echo -e "\n${GREEN}${SCRIPTNAME}${NORMAL} - simple bootstick tool\n"
fi

# }}}

# {{{ Check for updates

if ( update_available )
then
    message "info" "There is an update available for this script"\!\!\!
fi

# }}}



# {{{ Check existing sticks
devices=$( list_devices )
devices_count=$( echo -n "${devices}" | wc -w )
devices_pretty=$( list_devices_pretty )

if ( $VERBOSE )
then
    message info "Available devices:"
    if [ -z "$devices" ]
    then
        echo -e "\tNone"
    else
        indented echo "${devices}"
    fi
    echo -e "${devices_count} devices found\n"
fi

if [ ${devices_count} -eq 0 ]
then
    message "error" "No devices found"
    exitclean 1
fi

for dev in ${devices}
do
    for part in $( get_partitions ${dev} )
    do
        if [ "$( get_label /dev/${part} )" == "Bootstick" ]
        then
            TARGET="/dev/${part}"
            DEV=$( echo ${TARGET} | sed 's|[0-9]||g' )
            break
        fi
    done
done

# }}}

# {{{ Choose stick

if [ -z "${TARGET}" ]
then
    if [ ${devices_count} -gt 0 ]
    then
        i=0
        for dev in ${devices}
        do
            i=$(( $i + 1 ))
            echo "${i}) ${dev} - $( get_size ${dev} )"
        done
    fi

    read -p "> "
    echo 

    if ( echo "x${REPLY}" | grep -q "^x[1-${devices_count}]$" )
    then
        DEV=$( echo ${devices} | tr " " "\n" | head -n ${REPLY} | tail -n 1 )
    else
        message error "Canceled because of invalid choice."
        exitclean 1
    fi

    message_verbose info "Using device: ${DEV}"
else
    message info "Using already initalized stick: ${DEV}"
fi

# }}}

# {{{ Mountpoint

trap cleanup 0

DIR="/tmp/usbstick.$$.tmp"
mkdir -p "${DIR}"

message_verbose info "Using temporary dir '${DIR}'"

mkdir -p "${DIR}/mnt/"
mkdir -p "${DIR}/iso/"

# }}}

# {{{ Check the choosen stick

partitions=$( get_partitions ${DEV} )

if ( $VERBOSE )
then
    message info "choosen dev (${DEV}) has following partitions:"
    indented echo -e ${partitions:-"None"}"\n"
fi

TARGET=
for partition in $partitions
do
    if [ "x$( get_label /dev/${partition} )" == "xBootstick" ]
    then
        TARGET="/dev/${partition}"
        break
    fi
done

if [ -n "${TARGET}" ]
then
    message info "Already initalized stick found. Using '${TARGET}'."
fi

# }}}

# {{{ Check Size

if ! [ "xGB" == "x$( get_size ${DEV} | sed 's|[0-9,\.]||g' )" ]
then
    message "error" "Drive size not in GB. Can not continue."
    exitclean 1 
fi

if [ $( get_size ${DEV} | sed 's|[A-Za-z]||g' | cut -f'1' -d'.' | cut -f'1' -d',' ) -lt 8 ]
then
    message "error" "Device is only $( get_size ${DEV} ). Should be at least 8GB."
fi

# }}}

# {{{ Partition stick (if non update)

if [ -z "${TARGET}" ]
then
    echo -e "No initalized partition found. Should I create a fresh bootstick on '${DEV}'?"
    echo -e "EVERYTHING ON '${DEV}' WILL BE DELETED"\!\!\!
    echo -e "Type uppercase 'yes' to continue."
    read -p "> "
    echo 

    if ! [ "x${REPLY}" == "xYES" ]
    then
        message error "Canceled because of user choice."
        exitclean 0
    fi
    
    TARGET="${DEV}1"
    message info "Partitioning and formating the Stick"
    message_verbose info "Writing fresh Label to Stick"
    if ! ( parted -s ${DEV} mklabel msdos )
    then
        message error "Error while writing msdos disklabel to stick"
        exitclean 1
    fi

    message_verbose "info" "Creating first Partition"
    if ! ( parted -s ${DEV} mkpart primary 1M $( get_size ${DEV} ) )
    then
        message "error" "Error while creating first Partition on the stick"
        exitclean 1
    fi
    
    message_verbose info "Formating (ext3) first Partition with Label 'Bootstick'"
    if ! ( mkfs.ext3 -L Bootstick -q ${TARGET} )
    then 
        message "error" "Error while formating first Partition"
        exitclean 1
    fi
fi

# }}}

# {{{ Mounting stick / Checking Directorys
    
message_verbose "info" "Mounting ${TARGET} ${DIR}/mnt/"
if ! ( mount ${TARGET} ${DIR}/mnt/ )
then
    message error "Could not mount target partition '${TARGET}'"
    exitclean 1
fi

if ! [ -d ${DIR}/mnt/images/ ]
then
    mkdir -p ${DIR}/mnt/images/
fi

# }}}

# {{{ Install / Update grml96 

if ( $CONFIG_ENABLE_GRML96 )
then
    #SOURCE_GRML96_NAME="grml96"
    #SOURCE_GRML96_DESC="grml (multiarch)"
    #SOURCE_GRML96_UPDATEVERSION=1
    SOURCE_GRML96_FILENAME=$( basename ${SOURCE_GRML96_URL} ) 
    SOURCE_GRML96_ARCHIVE=${CONFIG_IMAGES_DIR}/${SOURCE_GRML96_FILENAME}
    SOURCE_GRML96_TARGET_DIR=${DIR}/mnt/images/grml96
    SOURCE_GRML96_TARGET=${SOURCE_GRML96_TARGET_DIR}/${SOURCE_GRML96_FILENAME}

    if ! [ -d $( dirname ${SOURCE_GRML96_TARGET} ) ]
    then
        mkdir -p $( dirname ${SOURCE_GRML96_TARGET} )
    fi

    if [ -e ${SOURCE_GRML96_TARGET} ]
    then
        message "info" "${SOURCE_GRML96_FILENAME} already available on stick"
    fi

    if [ -e ${SOURCE_GRML96_TARGET} ] && ( check_checksum ${SOURCE_GRML96_CHECKSUM} ${SOURCE_GRML96_TARGET} )
    then
        message "info" "Image on stick is valid and up-to-date."
    else
        if ! [ -e ${SOURCE_GRML96_ARCHIVE} ]
        then
            message "info" "${SOURCE_GRML96_FILENAME} already available in image folder"
        fi

        if ! [ -e ${SOURCE_GRML96_ARCHIVE} ] || ! ( check_checksum ${SOURCE_GRML96_CHECKSUM} ${SOURCE_GRML96_ARCHIVE} )
        then
            message "info" "Starting download of ${SOURCE_GRML96_FILENAME}"
            if ! ( wget -O ${SOURCE_GRML96_ARCHIVE} "${SOURCE_GRML96_URL}" ) || ! ( check_checksum ${SOURCE_GRML96_CHECKSUM} ${SOURCE_GRML96_ARCHIVE} )
            then
                message "error" "Error downloading grml96 image"
                exitclean 1
            else
                message "info" "Download is valid."
            fi
        else
            message "info" "Image in images folder is valid and up-to-date."
        fi
        
        message "info" "Copying grml96 image to stick"
        if ! ( cp ${SOURCE_GRML96_ARCHIVE} ${SOURCE_GRML96_TARGET} )
        then
            message "error" "Error while copying grml96 image to stick"
            exitclean 1
        else
            message "info" "Image successful copied to stick"
        fi
    fi
    
    if [ -d ${SOURCE_GRML96_TARGET_DIR}/boot/ ]
    then
        rm -rf ${SOURCE_GRML96_TARGET_DIR}/boot/ 2>/dev/null
    fi

    message_verbose info "mounting grml96 iso"
    mount -t iso9660 -o loop,ro ${SOURCE_GRML96_TARGET} ${DIR}/iso/
    
    message_verbose info "copying /boot/ from grml iso"
    cp -r ${DIR}/iso/boot/ ${SOURCE_GRML96_TARGET_DIR}/boot/
    
    message_verbose info "unmounting grml96 iso"
    umount ${DIR}/iso/ 

    if ! ( ${CONFIG_IMAGES_KEEP} ) && [ -e ${SOURCE_GRML96_ARCHIVE} ]
    then
        message "info" "Deleting grml image from image folder"
        rm -f ${SOURCE_GRML96_ARCHIVE}
    fi
    
    echo "grml96:${SOURCE_GRML96_UPDATEVERSION}" >> ${DIR}/mnt/images/versions
else
    message_verbose info "Skipping Image grml96"
fi

echo

# }}}

# {{{ Install / Update backtrack32 

if ( $CONFIG_ENABLE_BT32 )
then

    if ! [ -d ${DIR}/mnt/images/backtrack32 ]
    then
        mkdir -p ${DIR}/mnt/images/backtrack32
    fi

else
    message info "Skipping Image backtrack32"
fi

echo

# }}}

# {{{ Install / Update backtrack64

if ( $CONFIG_ENABLE_BT64 )
then

    if ! [ -d ${DIR}/mnt/images/backtrack64 ]
    then
        mkdir -p ${DIR}/mnt/images/backtrack64
    fi

else
    message info "Skipping Image backtrack64"
fi

echo

# }}}

# {{{ Install / Update Extras

message info "UNIMPLEMENTED - Skipping 'install/update extras'"

# }}}

# {{{ Install / Update bootloader

grubcfg=${DIR}/mnt/grub/grub.cfg

message "info" "Installing Grub2"
if ! ( grub-install --boot-directory=${DIR}/mnt/ ${DEV} )
then
    message "error" "error while writing bootloader."
    exitclean 1
fi

message "info" "Generating grub.cfg"
echo "" > ${grubcfg}
echo "set timeout=-1" >> ${grubcfg}
echo "set default=0" >> ${grubcfg}
echo "set fallback=1" >> ${grubcfg}
echo "" >> ${grubcfg}

if ( $CONFIG_ENABLE_GRML96 )
then
    #sed -i -e 's|linux\ */|linux (loop)/|g' -e 's|initrd\ */|initrd (loop)/|g' -e 's|linux16\ */|linux16 (loop)/|g' -e 's|initrd16\ */|initrd16 (loop)/|g' -e 's|module\ */boot/|module\ (loop)/boot/|g' -e 's|multiboot\ *|multiboot\ (loop)/boot/|g' \
    
        
    sed -i -e 's|linux\ */|linux (loop)/|g' -e 's|initrd\ */|initrd (loop)/|g' -e 's|linux16\ */|linux16 (loop)/|g' -e 's|initrd16\ */|initrd16 (loop)/|g' \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/grml32full_default.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/grml64full_default.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/grml32full_options.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/grml64full_options.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/addons.cfg 

    sed -i "s|theme=/boot/|theme=/images/grml96/boot/|g" ${SOURCE_GRML96_TARGET_DIR}/boot/grub/header.cfg

    sed -i 's|\ \(/boot/grub/\)|\ /images/grml96\1|g' \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/grub.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/header.cfg \
            ${SOURCE_GRML96_TARGET_DIR}/boot/grub/addons.cfg 
    
    echo "submenu \"grml96 ->\" --class=submenu {" >> ${grubcfg}
    echo -e "\tinsmod ext2" >> ${grubcfg}
    echo -e "\tloopback loop \"/images/grml96/grml96-full_2012.05.iso\"" >> ${grubcfg}
    echo -e "\tiso_path=\"/images/grml96/grml96-full_2012.05.iso\"" >> ${grubcfg}
    echo -e "\texport iso_path" >> ${grubcfg}
    echo -e "\tsource /images/grml96/boot/grub/grub.cfg" >> ${grubcfg}
    echo -e "\tset timeout=-1" >> ${grubcfg}
    echo "}" >> ${grubcfg}
    echo "" >> ${grubcfg}
fi

if ( $CONFIG_ENABLE_BT32 )
then
    echo "submenu \"backtrack32 ->\" --class=submenu {" >> ${grubcfg}
    echo "}" >> ${grubcfg}
    echo "" >> ${grubcfg}
fi

if ( $CONFIG_ENABLE_BT64 )
then
    echo "submenu \"backtrack64 ->\" --class=submenu {" >> ${grubcfg}
    echo "}" >> ${grubcfg}
    echo "" >> ${grubcfg}
fi

echo "" >> ${grubcfg}
echo "" >> ${grubcfg}

# }}}

exitclean `${SUCCESS}`

