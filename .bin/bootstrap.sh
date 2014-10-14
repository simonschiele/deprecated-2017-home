#!/bin/bash
LANG=C

# build testimage:
# qemu-img create -f qcow2 image_large.img 30G
# qemu-img resize image_medium.img +2G

### !!! CONFIG !!! #########################################
#
# best overwrite by export before running this script:
# export BOOTSTRAP_HOSTNAME="virt12.cnet.loc"
# export BOOTSTRAP_TARGET="/dev/sda"
# export BOOTSTRAP_SYSTEMTYPE="workstation"
# ./bootstrap.sh
#
BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME:-"test.cnet.loc"}
BOOTSTRAP_SYSTEMTYPE=${BOOTSTRAP_SYSTEMTYPE:-"minimal"}
BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME:-"simon"}
BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET:-"/dev/sdX"}
BOOTSTRAP_MOUNT=${BOOTSTRAP_MOUNT}
BOOTSTRAP_64=${BOOTSTRAP_64:-false}
BOOTSTRAP_RAID=${BOOTSTRAP_RAID:-false}
BOOTSTRAP_SSD=${BOOTSTRAP_SSD:-true}
BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE:-"testing"}
BOOTSTRAP_COMPONENTS=${BOOTSTRAP_COMPONENTS:-main,contrib,non-free}
BOOTSTRAP_MIRROR=${BOOTSTRAP_MIRROR:-"http://ftp2.de.debian.org/debian"}
BOOTSTRAP_LAYOUT=${BOOTSTRAP_LAYOUT}
BOOTSTRAP_PACKAGES=${BOOTSTRAP_PACKAGES}
############################################################
DEPENDS="parted debootstrap cryptsetup"
DEBIAN_DEPENDS="e2fsprogs qemu-utils git"
REPO_HOME="http://simon.psaux.de/git/home.git/plain"
MIN_SIZE=4096
############################################################
verbose=false
nocolor=false
coloring=false
cleanup=( )
sudo=""

# {{{ functions

function usage() {
    echo
    echo "Simons debian bootstrap wrapper"
    echo
    echo "$( basename ${0} ) [options]"
    echo 
    echo "Options:"
    echo " -h | --help          | this info"
    echo " -v | --verbose       | activate verbose mode"
    echo " -n | --nocolor       | disable coloring"
    echo
    echo "Configuration bootstrap itself via export like this:"
    echo "> export BOOTSTRAP_HOSTNAME=\"testhost.cnet.loc\""
    echo
    echo "Possible config variables:"
    echo -e "\tBOOTSTRAP_HOSTNAME\t\t(like \"testhost.cnet.loc\")"
    echo -e "\tBOOTSTRAP_SYSTEMTYPE\t\t(like \"workstation\")"
    echo -e "\tBOOTSTRAP_USERNAME\t\t(like \"simon\")"
    echo -e "\tBOOTSTRAP_TARGET\t\t(like \"/dev/sdc\")"
    echo -e "\tBOOTSTRAP_MOUNT\t\t\t(like \"/media/root\")"
    echo -e "\tBOOTSTRAP_64\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_RAID\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_SSD\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_SUITE\t\t\t(like \"testing\")"
    echo -e "\tBOOTSTRAP_MIRROR\t\t(like \"http://ftp2.de.debian.org/debian\")"
    echo -e "\tBOOTSTRAP_LAYOUT\t\t(like \"small,medium,big\")"
    echo -e "\tBOOTSTRAP_PACKAGES\t\t(like \"emacs,mercurial\")"
    echo
    settings
    echo
    exit 0
}

function settings() {
    echo -e "\thostname: ${BOOTSTRAP_HOSTNAME}"
    echo -e "\tsystemtype: ${BOOTSTRAP_SYSTEMTYPE}"
    echo -e "\tdefault user: ${BOOTSTRAP_USERNAME}"
    echo -e "\ttarget: ${BOOTSTRAP_TARGET}"
    echo -e "\tmount: ${BOOTSTRAP_MOUNT}"
    echo -e "\t64bit: ${BOOTSTRAP_64}"
    echo -e "\traid: ${BOOTSTRAP_RAID}"
    echo -e "\tssd: ${BOOTSTRAP_SSD}"
    echo -e "\tsuite: ${BOOTSTRAP_SUITE}"
    echo -e "\tcomponents: ${BOOTSTRAP_COMPONENTS}"
    echo -e "\tlayout: ${BOOTSTRAP_LAYOUT}"
    echo -e "\tmirror: ${BOOTSTRAP_MIRROR}"
    echo -e "\tpackages: ${BOOTSTRAP_PACKAGES}"
}

function output() {
    local msg="${1:-'Unknown Message'}"
    local msgType=${2:-"DEBUG"}
 
    if ( $coloring ) ; then
        case "${msgType}" in
            ERROR)   local msgColor="red" ;;
            WARNING) local msgColor="yellow" ;;
            LOG)     local msgColor="green" ;;
            DEBUG)   local msgColor="blue" ;;
            CLEANUP) local msgColor="white" ;;
            *)       local msgColor="black" ;;
        esac
        
        echo "$( color ${msgColor} )[${msgType}]$( color ) ${msg}"
    else
        echo "[${msgType}] ${msg}"
    fi
}

function error() {
    msg="${1:-'Unknown Error'}"
    output "${msg}" "ERROR" >&2
    exit ${2:-1}
}

function debug() {
    ( $verbose ) && output "${@:-'Unknown Debug'}" "DEBUG"
}

function warning() {
    output "${@:-'Unknown Log'}" "WARNING"
}

function log() {
    output "${@:-'Unknown Log'}" "LOG"
}

function depends() {
    local name="${1}"
    local dependsType="${2:-bin}"
    local available=false
    
    case "${dependsType}" in
        debian) ( dpkg -l | grep -iq "^ii\ \ ${name}\ " ) && available=true ;;
        bin)    ( $sudo which ${name} >/dev/null ) && available=true ;;
        *)      ( depends ${name} bin ) && available=true ;;
    esac
    
    return $( ${available} )
} 

function getFreeDevice() {
    name=${1:-nbd}
    class=${2:-block}
    
    for i in $( ls /dev/${name}* | grep -o [0-9]* | sort -n ) ; do 
        if [ $( cat /sys/class/${class}/${name}${i}/size ) -eq 0 ] ; then
            echo "$i" 
            return 0
        fi
    done 
    
    return 1
}

function cleanupTrap() {
    echo
    cnt=$(( ${#cleanup[@]} - 1 ))
    for key in $( seq ${cnt} -1 0 ) ; do
        case "${cleanup[$key]}" in
            
            crypto)
                output "umount ${BOOTSTRAP_MOUNT}" "CLEANUP"
                $sudo umount ${BOOTSTRAP_MOUNT} || warning "couldn't umount /chroot/"
                 
                if ( cryptsetup status /dev/mapper/install_root >/dev/null 2>&1 ) ; then
                    output "closing luks device /dev/mapper/install_root" "CLEANUP"
                    $sudo cryptsetup luksClose /dev/mapper/install_root || warning "couldn't close luks device" 
                fi
              ;;
            
            chroot)
                for d in boot/ proc sys dev/pts dev/ ; do
                    output "umount ${BOOTSTRAP_MOUNT}/${d}" "CLEANUP"
                    $sudo umount ${BOOTSTRAP_MOUNT}/${d} || warning "couldn't umount ${BOOTSTRAP_MOUNT}/${d}"
                done
              ;;
            
            nbd)
                output "disconnecting nbd devices" "CLEANUP"
                for dev in $( grep -v "^0$" /sys/class/block/nbd*/size | sed 's|.*\(nbd[0-9]*\).*|/dev/\1|g' ) ; do 
                    $sudo qemu-nbd --disconnect ${dev} >/dev/null 2>&1 || warning "failed to disconnect ${dev}"
                done
              ;;
            
            tempDir) 
                output "deleting tempDir ${tempDir}" "CLEANUP"
                $sudo rm -rf ${tempDir}
              ;;
            
            *) error "UNKNOWN CLEANUP KEY: ${cleanup[$key]}" ;;
        esac
    done
    
    # todo: keep flags
}

# }}}

# {{{ getopts 

log "Starting Bootstrap"
trap cleanupTrap EXIT

for arg ; do
    delim=""
    case "$arg" in
        --help) args="${args}-h ";;
        --verbose) args="${args}-v ";;
        --nocolor) args="${args}-n ";;
        --config) args="${args}-c ";;
        # pass through anything else
        *) [[ "${arg:0:1}" == "-" ]] || delim="\""
            args="${args}${delim}${arg}${delim} ";;
    esac
done

eval set -- "$args"
while getopts ":hvnc:" opt ; do
    case $opt in
        h)  usage ;;
        v)  verbose=true ;;
        n)  nocolor=true ;;
        c)  echo "using config: $OPTARG" ;;
        \?) usage ;;
        :)  echo "option -$OPTARG requires an argument"
            usage
        ;;
    esac
done

# }}}

# {{{ root/sudo

if [ $( id -u ) -eq 0 ] ; then
    debug "user already has root permissions - no sudo will be needed"
else
    depends sudo && sudo="sudo" || error "you are not root and there seems to be no 'sudo' available"
    debug "using sudo"
 
    if ( sudo -n echo -n >/dev/null 2>&1 ) ; then
        debug "using already authenticated 'sudo'"
    elif ( sudo echo -n ) ; then
        debug "user authenticated 'sudo' successfully"
    else
        error "sudo authentication failed and you are not root"
    fi
fi

# }}}

# {{{ init, includes, depends

depends wget || error "depends 'wget' missing"

tempDir=$( mktemp -d )
debug "tempDir created '${tempDir}'"
cleanup+=( "tempDir" )

debug "downloading 'resources.sh' from ${REPO_HOME}/"
wget -q -O ${tempDir}/resources.sh "${REPO_HOME}/.lib/resources.sh" || error "Failed to fetch resources.sh"
wget -q -O- "http://simon.psaux.de/git/home.git/plain/.packages" | grep -o "/[^\.]*\.list" | while read list ; do
    debug "downloading '${list}' from ${REPO_HOME}/"
    wget -q -O ${tempDir}${list} "${REPO_HOME}/.packages${list}" || error "Failed to fetch ${list}"
done

debug "including '${tempDir}/resources.sh'"
. ${tempDir}/resources.sh 2>/dev/null || error "Failed to source resources.sh"

if ( $nocolor ) ; then
    debug "coloring disabled"
else
    coloring=true
    debug "activated coloring"
fi

for dep in ${DEPENDS} ; do 
    depends "${dep}" || error "depends '${dep}' missing"
done 

for dep in ${DEBIAN_DEPENDS} ; do 
    depends "${dep}" "debian" || error "depends '${dep}' missing"
done 

# }}}

# {{{ check config 
[ -z "${BOOTSTRAP_HOSTNAME}" ] && error "BOOTSTRAP_HOSTNAME empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_SYSTEMTYPE}" ] && error "BOOTSTRAP_SYSTEMTYPE empty. please configure. have a look at --help."
[ -e "${tempDir}/${BOOTSTRAP_SYSTEMTYPE}.list" ] || error "no package config for this systemtype"
[ -z "${BOOTSTRAP_USERNAME}" ] && error "BOOTSTRAP_USERNAME empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_TARGET}" ] && error "BOOTSTRAP_TARGET empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_64}" ] && error "BOOTSTRAP_64 empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_RAID}" ] && error "BOOTSTRAP_RAID empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_SSD}" ] && error "BOOTSTRAP_SSD empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_SUITE}" ] && error "BOOTSTRAP_SUITE empty. please configure. have a look at --help."
[ -z "${BOOTSTRAP_MIRROR}" ] && error "BOOTSTRAP_MIRROR empty. please configure. have a look at --help."
#${BOOTSTRAP_COMPONENTS:-main,contrib,non-free}

if [ -z "${BOOTSTRAP_MOUNT}" ] ; then
    BOOTSTRAP_MOUNT="${tempDir}/chroot"
fi

if [ -z "$BOOTSTRAP_PACKAGES" ] ; then
    packageLists=$( ( echo "${tempDir}/${BOOTSTRAP_SYSTEMTYPE}.list" ; grep "^\.\ " ${tempDir}/${BOOTSTRAP_SYSTEMTYPE}.list | sed "s|^\.\ |${tempDir}/|g" ) | xargs )
    BOOTSTRAP_PACKAGES=$( grep -v -h -e "^\ *$" -e "^[#\.]" $packageLists | cut -f"2-" -d":" | sort -u | xargs )
    debug "BOOTSTRAP_PACKAGES loaded from ${packageLists}"
else
    debug "BOOTSTRAP_PACKAGES are set via export - will not load the systemtype packagelists"
fi

settings | while read line ; do log "${line}" ; done

# }}}

# {{{ check target  

targetBlockdevice=true
if [ "${BOOTSTRAP_TARGET}" = "/dev/sdX" ] ; then 
    error "no target device configured. please read --help carefully and configure at least the basic settings"
elif [ ! -e ${BOOTSTRAP_TARGET} ] ; then
    error "target device ${BOOTSTRAP_TARGET} not found"
elif [ ! -b ${BOOTSTRAP_TARGET} ] ; then
    if ( file "${BOOTSTRAP_TARGET}" | grep -qi -e "image" -e "boot sector" ) ; then
        debug "device '${BOOTSTRAP_TARGET}' not a valid blockdevice, will treat it as image file"
        targetBlockdevice=false
        
        if ! ( lsmod | grep -qi "^nbd\ " ) ; then
            $sudo modprobe -av nbd || error "couldn't load nbd module, but device is image"
        fi
         
        BOOTSTRAP_TARGET_ORIG=${BOOTSTRAP_TARGET}
        BOOTSTRAP_TARGET="/dev/nbd$( getFreeDevice nbd )"
        $sudo qemu-nbd -c ${BOOTSTRAP_TARGET} ${BOOTSTRAP_TARGET_ORIG}
        cleanup+=( "nbd" )
        debug "device '${BOOTSTRAP_TARGET}' -> '${BOOTSTRAP_TARGET_ORIG}'"
    else
        error "target is not a blockdevice and not an image"
    fi
fi

targetSize=$( $sudo parted -sm ${BOOTSTRAP_TARGET} unit mb print 2>&1 | grep -o "^${BOOTSTRAP_TARGET}:[0-9]*" | cut -f'2' -d':' )
debug "target device size: ${targetSize}MB"

if [ ${targetSize} -lt ${MIN_SIZE} ] ; then
    error "target device ${BOOTSTRAP_TARGET} to small. ${MIN_SIZE}MB are needed"
fi
    
if [ -z "${BOOTSTRAP_LAYOUT}" ] ; then
    if [ $targetSize -lt 8192 ] ; then
        BOOTSTRAP_LAYOUT="small"
    elif [ $targetSize -lt 32768 ] ; then
        BOOTSTRAP_LAYOUT="medium"
    elif [ $targetSize -ge 32768 ] ; then
        BOOTSTRAP_LAYOUT="big"
    fi
else
    if ! ( echo "$BOOTSTRAP_LAYOUT" | grep -qie "^small$" -e "^medium$" -e "^big$" ) ; then
        error "unknown BOOTSTRAP_LAYOUT. allowed values: small, medium, big."
    fi
fi
debug "LAYOUT: ${BOOTSTRAP_LAYOUT}"

# }}}

# {{{ prepare harddisk 

warning "!!! This will destroy everything on device ${BOOTSTRAP_TARGET} !!!"
read -p "To continue type uppercase 'yes': "
if [ "x${REPLY}" != "xYES" ] ; then
    error "user canceled bootstrap" 2
fi

debug "writing msdos label to target"
$sudo parted -s ${BOOTSTRAP_TARGET} mklabel msdos #>> log/step1.log
    
if [ "${BOOTSTRAP_LAYOUT}" = "small" ] ; then
    debug "creating partitions (256mb <-> rest <-> 1024mb)"
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M 256M #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 256M $(( ${targetSize} - 1024 )) #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary $(( ${targetSize} - 1024 )) ${targetSize} #>> log/step1.log
elif [ "${BOOTSTRAP_LAYOUT}" = "medium" ] ; then
    debug "creating partitions (1280mb <-> rest <-> 2048mb)"
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M 1280M #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 1280M $(( ${targetSize} - 2048 )) #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary $(( ${targetSize} - 1024 )) ${targetSize} #>> log/step1.log
elif [ "${BOOTSTRAP_LAYOUT}" = "big" ] ; then
    debug "creating partitions (8192mb <-> rest <-> 4096mb)"
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M 8192M #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary 8192M $(( ${targetSize} - 4096 )) #>> log/step1.log
    $sudo parted -s ${BOOTSTRAP_TARGET} mkpart primary $(( ${targetSize} - 4096 )) ${targetSize} #>> log/step1.log
fi

( $targetBlockdevice ) && suffix= || suffix="p"
sync ; $sudo sync ; partprobe ; $sudo partprobe

debug "format '/boot' as ext3"
$sudo mkfs.ext3 -q -F -L boot ${BOOTSTRAP_TARGET}${suffix}1 || error "failed to format /boot"

log "crypting root"
$sudo luksformat ${BOOTSTRAP_TARGET}${suffix}2 || error "luksformat failed"
[ -e /dev/mapper/install_root ] && error "/dev/mapper/install_root is already in use"
$sudo cryptsetup luksOpen ${BOOTSTRAP_TARGET}${suffix}2 install_root || error "couldn't open luks device"
cleanup+=( "crypto" )

debug "format '/' as btrfs"
$sudo mkfs.btrfs -f -L root /dev/mapper/install_root || error "failed to format /root"

debug "creating 'swap'"
$sudo mkswap -L swap ${BOOTSTRAP_TARGET}${suffix}3 || warning "failed to create swap" 

# }}}

# {{{ mount stuff

$sudo mkdir -p ${BOOTSTRAP_MOUNT}
$sudo mount /dev/mapper/install_root ${BOOTSTRAP_MOUNT} || error "couldn't mount root"
cleanup+=( "chroot" )

$sudo mkdir -p ${BOOTSTRAP_MOUNT}/boot/
$sudo mount ${BOOTSTRAP_TARGET}${suffix}1 ${BOOTSTRAP_MOUNT}/boot/ || error "couldn't mount boot"

# }}}

# {{{ bootstrap

[ -n "${BOOTSTRAP_PACKAGES}" ] && packages="--include=$( echo \"${BOOTSTRAP_PACKAGES}\" | sed 's|\ |,|g')" || packages=""
[ -n "${BOOTSTRAP_COMPONENTS}" ] && components="--components=\"${BOOTSTRAP_COMPONENTS}\"" || components=""

packages='--include="vim,sudo,ssh"'
log "starte bootstrapping"
$sudo debootstrap ${packages} ${components} ${BOOTSTRAP_SUITE} ${BOOTSTRAP_MOUNT} ${BOOTSTRAP_MIRROR} >/dev/null || error "bootstrap failed" 
log "bootstrapping successfull"

# }}}

# {{{ prepare chroot

for dir in /dev/ /dev/pts /sys/ /proc/ ; do
    debug "bind-mount ${dir} -> ${BOOTSTRAP_MOUNT}${dir}"
    [ ! -e ${BOOTSTRAP_MOUNT}${dir} ] && $sudo mkdir ${BOOTSTRAP_MOUNT}${dir}
    $sudo mount -o bind ${dir} ${BOOTSTRAP_MOUNT}${dir} || error "couldn't bind-mount ${dir}" 
done

# }}}

# {{{ repos 

debug "clone home.git"
$sudo git clone http://simon.psaux.de/git/home.git ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME} 

for i in firewall.git initramfs-hooks.git grub-stuff.git ; do
    debug "clone ${i}"
    $sudo git clone http://simon.psaux.de/git/${i} ${BOOTSTRAP_MOUNT}/usr/src/${i} || warning "couldn't check out ${i}"
done

# }}}

# {{{ system

echo "system_hostname=\"${BOOTSTRAP_HOSTNAME}\"" > ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME}/.system.conf 
echo "system_domain=\"${BOOTSTRAP_DOMAIN}\"" >> ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME}/.system.conf 
echo "system_type=\"${BOOTSTRAP_SYSTEMTYPE}\"" >> ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME}/.system.conf 
echo "system_username=\"${BOOTSTRAP_USERNAME}\"" >> ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME}/.system.conf 
echo "#################################################" >> ${BOOTSTRAP_MOUNT}/home/${BOOTSTRAP_USERNAME}/.system.conf

# todo: use UUID!
echo ">>> Creating /etc/fstab"
#echo -e "${BOOTSTRAP_TARGET}1\t/boot\text3\tdefault\t0 0" > ${BOOTSTRAP_MOUNT}/etc/fstab
#echo -e "/dev/mapper/root\t/\tbtrfs\tautodefrag,noatime,rw,ssd,compress,thread_pool=32\t0 0" >> ${BOOTSTRAP_MOUNT}/etc/fstab

echo ">>> Creating /etc/crypttab"
#echo -e "root\t${BOOTSTRAP_TARGET}2\tnone\tluks" > ${BOOTSTRAP_MOUNT}/etc/crypttab

# }}}

exit 0 

# {{{ 
# }}}

echo ">>> Copy installer logfiles to ${BOOTSTRAP_MOUNT}/installer/"
cp -r log/ ${BOOTSTRAP_MOUNT}/installer/

echo ">>> Creating settings.sh for step2"
echo '#!/bin/bash' > ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
[...]

cat >${BOOTSTRAP_MOUNT}/installer/bootstrap2.sh << 'EOF'
#!/bin/bash

errorexit() {
    echo "[ERROR] ${@}" 
    exit 1
}

if ( echo $0 | grep -q -e "^/*installer/" )
then
    cd /installer/
fi

if [ ! -r ./settings.sh ]
then
    echo "[ERROR] Could not find 'settings.sh' while executing 'bootstrap2.sh'"
    exit 1
fi

HOOKS=true
if [ ! -d ./hooks/ ]
then
    echo "[WARNING] Could not find hooks/ folder"
    HOOKS=false
fi

PACKAGES=true
if [ ! -d ./packages/ ]
then
    echo "[WARNING] Could not find packages/ folder"
    PACKAGES=false
fi

echo ">>> Starting step2 (inside chroot)"

echo ">>> Reading config settings"
eval $( grep ^BOOTSTRAP_ ./settings.sh )
BOOTSTRAP_HOME="/home/${BOOTSTRAP_USERNAME}"

echo ">>> Setting up locales"
echo "set locales/default_environment_locale de_DE.UTF-8" | sudo debconf-communicate
echo "set locales/locales_to_be_generated de_DE.UTF-8 UTF-8" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive locales

echo ">>> Reconfiguring Debconf"
echo "set debconf/frontend Dialog" | sudo debconf-communicate
echo "set debconf/priority high" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive debconf

echo ">>> Setting up keyboard (via debconf)"
echo "set keyboard-configuration/layout German" | sudo debconf-communicate
echo "set keyboard-configuration/variant German - German (eliminate dead keys)" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive keyboard-configuration

echo ">>> Setting clock/timezone"
echo "set tzdata/Areas Europe" | sudo debconf-communicate
echo "set tzdata/Zones/Etc UTC" | sudo debconf-communicate
echo "set tzdata/Zones/Europe Berlin" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive tzdata
hwclock --utc
ntpdate time.fu-berln.de
hwclock --systohc

echo ">>> Creating default User '${BOOTSTRAP_USERNAME}'"
useradd -m -U -s /bin/bash ${BOOTSTRAP_USERNAME}

echo ">>> Changing password for User '${BOOTSTRAP_USERNAME}'"
passwd ${BOOTSTRAP_USERNAME}

echo ">>> Changing password for User 'root'"
passwd root

echo ">>> Setting up apt (better use hook)"
echo 'deb http://security.debian.org/ testing/updates main contrib non-free' > /etc/apt/sources.list
echo 'deb http://ftp2.de.debian.org/debian testing main contrib non-free' >> /etc/apt/sources.list
apt-get update

echo ">>> Checking out home.git (+ subrepos)"
rm -rf ${BOOTSTRAP_HOME} 
git clone --recursive http://simon.psaux.de/git/home.git ${BOOTSTRAP_HOME}
chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME}/ -R
. ${BOOTSTRAP_HOME}/.bashrc
mkdir ${BOOTSTRAP_HOME}/Downloads
    
echo ">>> Installing Kernel and Bootloader (better use hook)"
apt-get install grub2 linux-image-2.6-686-pae linux-headers-2.6-686-pae firmware-linux-free firmware-linux-nonfree firmware-realtek firmware-iwlwifi
    
echo ">>> Writing ${BOOTSTRAP_HOME}/.system.conf"
system_conf=${BOOTSTRAP_HOME}/.system.conf
echo -e "hostname=\"$( echo $BOOTSTRAP_HOSTNAME | cut -f'1' -d'.' )\"" > $system_conf
echo -e "domain=\"${BOOTSTRAP_DOMAIN:-$( echo $BOOTSTRAP_HOSTNAME | cut -s -f'2-' -d'.' )}\"" >> $system_conf
echo -e "systemtype=\"${BOOTSTRAP_SYSTEMTYPE}\"" >> $system_conf
echo -e "username=\"${BOOTSTRAP_USERNAME}\"" >> $system_conf

if ( $PACKAGES )
then
    echo ">>> Installing packages for systemtype '${BOOTSTRAP_SYSTEMTYPE}'"
    apt-get install $( cat $( grep '^\.\ ' ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed 's|^\. *||g' | sed 's|^|./|g' | xargs ) ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' -e 's|[ ]|\n|g' | sed '/^$/d' | sort -u | xargs )
fi

if ! ( $HOOKS )
then
    echo ">>> Executing non-optional Hooks for systemtype '${BOOTSTRAP_SYSTEMTYPE}'"
    find hooks/* | while read hook
    do 
        if (( grep -iq ^hook_systemtype.*${BOOTSTRAP_SYSTEMTYPE} $hook ) && ( grep -iq ^hook_optional.*false $hook ))
        then 
            echo ">>> Executing './${hook}'"
            ./${hook}
        fi
    done
fi

groups="audio video plugdev netdev fuse sudo"
echo ">>> Adding User '${BOOTSTRAP_USERNAME}' to default groups:"
echo "> $groups"
for group in $groups
do
    usermod -a -G ${group} ${BOOTSTRAP_USERNAME}
done

echo ">>> Setting minimal permissions (better use hook)"
chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME} -R 
find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;

# finished
echo
echo 'Bootstrap + Autoconfiguration is finished!'
echo 
echo 'Please copy/install/configure by hand:'
echo '* fonts'
echo '* keys' 
echo 
echo 'Enjoy your new system!' 
echo 

EOF
chmod 770 ${DESTDIR}/scripts/local-top/sleep

echo ">>> Starting step2 via chroot"
chroot ${BOOTSTRAP_MOUNT} /bin/bash /installer/bootstrap2.sh 

