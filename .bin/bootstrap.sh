#!/bin/bash
#
# Author: Simon Schiele (simon.codingmonkey@googlemail.com)
#
# This script creates a ready-to-use debian installation, based on debootstrap, 
# parted, cryptsetup, ...
#
# Check the help text for usage details
# > bootstrap.sh --help
#

LANG=C
SCRIPTNAME=$( basename ${0} )

declare -A LAYOUTS
LAYOUTS=( 
    [micro,boot]=64 [micro,swap]=256 [micro,auto_min]=990
    [mini,boot]=128 [mini,swap]=1024 [mini,auto_min]=3990
    [small,boot]=900 [small,swap]=2048 [small,auto_min]=7990
    [medium,boot]=1280 [medium,swap]=4096 [medium,auto_min]=11990
    [big,boot]=1280 [big,swap]=8096 [big,auto_min]=15990
    [huge,boot]=12288 [huge,swap]=12288 [huge,auto_min]=64990
)

BOOTSTRAP_SIMON=${BOOTSTRAP_SIMON:-false}
BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME:-test.cnet.loc}
BOOTSTRAP_SYSTEMTYPE=${BOOTSTRAP_SYSTEMTYPE:-minimal}
BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME:-simon}
BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET:-/dev/sdX}
BOOTSTRAP_ARCH=${BOOTSTRAP_ARCH:-amd64}
BOOTSTRAP_RAID=${BOOTSTRAP_RAID:-false}
BOOTSTRAP_SSD=${BOOTSTRAP_SSD:-true}
BOOTSTRAP_SWAP=${BOOTSTRAP_SWAP:-true}
BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE:-testing}
BOOTSTRAP_COMPONENTS=${BOOTSTRAP_COMPONENTS:-main,contrib,non-free}
BOOTSTRAP_MIRROR=${BOOTSTRAP_MIRROR:-http://ftp2.de.debian.org/debian}
BOOTSTRAP_MOUNT=${BOOTSTRAP_MOUNT}
BOOTSTRAP_LAYOUT=${BOOTSTRAP_LAYOUT}
BOOTSTRAP_PACKAGES_SYSTEMTYPE=${BOOTSTRAP_PACKAGES_SYSTEMTYPE:-true}
BOOTSTRAP_PACKAGES=${BOOTSTRAP_PACKAGES}

REPO_GIT="git@simon.psaux.de"
REPO_WEB="http://simon.psaux.de/git"

DEPENDS="parted debootstrap cryptsetup"
DEBIAN_DEPENDS="e2fsprogs qemu-utils git"
MIN_SIZE=1024

VERBOSE=false
NOCOLOR=false
COLORING=false
USAGE=false
CONFIG=false
KEEP=false
SUDO=""
CLEANUP=( )

# {{{ usage(), settings()

function usage() {
    echo
    echo "Simons debian bootstrap wrapper"
    echo
    echo "$SCRIPTNAME [options]"
    echo
    echo "Options:"
    echo " -h | --help          | this info"
    echo " -k | --keep          | dont't umount chroot and don't delete tmpDir"
    echo " -c | --config        | show config values"
    echo " -v | --verbose       | activate verbose mode"
    echo " -n | --nocolor       | disable coloring"
    echo
    echo "Configuration of the bootstrap settings itself, via environment like this:"
    echo " > export BOOTSTRAP_SIMON=\"true\""        #todo: remove this line
    echo " > export BOOTSTRAP_HOSTNAME=\"testhost.cnet.loc\""
    echo " > export BOOTSTRAP_MIRROR=\"http://localhost:3142/debian\""
    echo " > export BOOTSTRAP_SUITE=\"unstable\""
    echo " > export BOOTSTRAP_SYSTEMTYPE=\"minimal\""
    echo " > $SCRIPTNAME -v -k"
    echo
    echo "Possible config variables:"
    echo -e "\tBOOTSTRAP_HOSTNAME\t\t(like \"testhost.cnet.loc\")"
    echo -e "\tBOOTSTRAP_SYSTEMTYPE\t\t(like \"workstation\")"
    echo -e "\tBOOTSTRAP_USERNAME\t\t(like \"simon\")"
    echo -e "\tBOOTSTRAP_TARGET\t\t(like \"/dev/sdc\")"
    echo -e "\tBOOTSTRAP_MOUNT\t\t\t(like \"/media/root\")"
    echo -e "\tBOOTSTRAP_ARCH\t\t\t(like amd64,i386)"
    echo -e "\tBOOTSTRAP_RAID\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_SSD\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_SWAP\t\t\t(like true|false)"
    echo -e "\tBOOTSTRAP_SIMON\t\t\t(like \"true|false\")"
    echo -e "\tBOOTSTRAP_SUITE\t\t\t(like \"testing\")"
    echo -e "\tBOOTSTRAP_MIRROR\t\t(like \"http://ftp2.de.debian.org/debian\")"
    echo -e "\tBOOTSTRAP_LAYOUT\t\t(like \"small,medium,big\")"
    echo -e "\tBOOTSTRAP_PACKAGES\t\t(like \"emacs,mercurial\")"
    echo
    
    if ( ! $VERBOSE ) ; then
        echo "To list available layouts, systemtypes, ... call in verbose mode:"
        echo " > $SCRIPTNAME --help --verbose" 
        echo "The help, verbose and config flag can be used combined:"
        echo " > $SCRIPTNAME -h -v -c" 
        echo 
    else
        echo "Possible layouts:"
        get_layouts | sed 's|^|\t|g'
        echo -e "\tauto|empty (selects one of the above based on device/image size)"
        echo 
    
        echo "Possible Systemtypes:"
        gitweb_ls "home.git" ".packages" | sort -u | sed -e 's|^|\t|g' -e 's|\.list||g'
        echo 
    fi

    if ( ! $CONFIG ) ; then
        echo "To see the actual config, start with --config flag:"
        echo " > $SCRIPTNAME --config" 
        echo ""
        echo "The help, verbose and config flag can be used combined:"
        echo " > $SCRIPTNAME -h -v -c" 
        echo 
    else
        echo "Settings at the moment:"
        settings | sed 's|^|\t|g'
        echo 
    fi

    exit 0
}

function settings() {
    set | grep "^BOOTSTRAP_[^=\ ]*=[^\ ]*$" \
        | sed -e 's|\(_MOUNT=\)$|\1<auto>@@@(temp@@@dir)|g' \
              -e 's|\(_LAYOUT=\)$|\1<auto>@@@(by@@@device/image@@@size)|g' \
              -e 's|\(_PACKAGES=\)$|\1<auto>@@@(by@@@systemtype@@@package@@@list)|g' \
        | sed 's|=|\t|g' \
        | column -c 80 -t \
        | sed 's|@@@|\ |g'
}

# }}}

# {{{ output(), error(), debug(), warning(), log() 

function output() {
    local msg="${1:-'Unknown Message'}"
    local msgType=${2:-"DEBUG"}
    local newline=${3:-true}
    
    if ( $newline ) ; then
        local echo="echo"
    else
        local echo="echo -n"
    fi

    if ( $COLORING ) ; then
        case "${msgType}" in
            ERROR)   local msgColor="red" ;;
            WARNING) local msgColor="yellow" ;;
            LOG)     local msgColor="green" ;;
            DEBUG)   local msgColor="blue" ;;
            CLEANUP) local msgColor="white" ;;
            *)       local msgColor="black" ;;
        esac

        $echo "$( color ${msgColor} )[${msgType}]$( color ) ${msg}"
    else
        $echo "[${msgType}] ${msg}"
    fi
}

function error() {
    msg="${1:-'Unknown Error'}"
    output "${msg}" "ERROR" >&2
    exit ${2:-1}
}

function debug() {
    ( $VERBOSE ) && output "${@:-'Unknown Debug'}" "DEBUG"
}

function warning() {
    output "${@:-'Unknown Log'}" "WARNING"
}

function log() {
    output "${@:-'Unknown Log'}" "LOG"
}

# }}}

# {{{ get_layouts(), get_layout_by_size(), get_layout()

function get_layouts() {
    declare -A seen
    for layout in "${!LAYOUTS[@]}" ; do
        local lay=$( echo $layout | cut -f1 -d, )
        if [ -z "${seen[${lay}]}" ] ; then
            seen[${lay}]=true
            echo "${lay}"
        fi
    done
    unset seen
} 

function get_layout_by_size() {
    local size=${1:-${BOOTSTRAP_TARGET_SIZE}}
    local nearest=0
    
    for lay in $( get_layouts ) ; do
        auto=$( get_layout $lay "auto_min" )
        if [ ${auto:-0} -gt ${nearest:-0} ] && [ ${auto:-0} -le ${size:-0} ]; then
            nearest=$auto
            local name=$lay
        fi
    done
    echo $name
}

function get_layout() {
    local layout=${1:-unknown}
    local part=${2:-all}
    get_layouts | grep -q "^${layout}$" || error "layout not found"
    
    [ "$part" = "all" ] || [ "$part" = "boot" ] && echo "${LAYOUTS[$layout,boot]}"
    [ "$part" = "all" ] || [ "$part" = "swap" ] && echo "${LAYOUTS[$layout,swap]}"
    [ "$part" = "all" ] || [ "$part" = "spare" ] && echo "${LAYOUTS[$layout,spare]}"
    [ "$part" = "all" ] || [ "$part" = "auto_min" ] && echo "${LAYOUTS[$layout,auto_min]}"
}


# }}}

# {{{ depends(), check_sudo(), get_credentials(), get_confirmation()

function depends() {
    local name="${1}"
    local dependsType="${2:-bin}"
    local available=false

    case "${dependsType}" in
        debian) ( dpkg -l | grep -iq "^ii\ \ ${name}\ " ) && available=true ;;
        bin)    ( $SUDO which ${name} >/dev/null ) && available=true ;;
        *)      ( depends ${name} bin ) && available=true ;;
    esac

    return $( ${available} )
}

function check_sudo() {
    if [ $( id -u ) -eq 0 ] ; then
        debug "user already has root permissions - no sudo will be needed"
    else
        depends sudo && SUDO="sudo" || error "you are not root and there seems to be no 'sudo' available"
        debug "using sudo"

        if ( sudo -n echo -n >/dev/null 2>&1 ) ; then
            debug "using already authenticated 'sudo'"
        elif ( sudo echo -n ) ; then
            debug "user authenticated 'sudo' successfully"
        else
            error "sudo authentication failed and you are not root"
        fi
    fi
}

function get_credentials() {
    output "Please supply credentials" "CREDENTIALS"
    output "Your Passphrase, first time: " "CREDENTIALS" "false"
    read -s pass_phrase ; echo

    output "Your Passphrase, second time: " "CREDENTIALS" "false"
    read -s pass_phrase_again ; echo

    if [ "x${pass_phrase}" != "x${pass_phrase_again}" ] ; then
        error "passphrases missmatch"
    fi

    output "Password for user '${BOOTSTRAP_USERNAME}', first time: " "CREDENTIALS" "false"
    read -s pass_user ; echo 
    output "Password for user '${BOOTSTRAP_USERNAME}', second time: " "CREDENTIALS" "false"
    read -s pass_user_again ; echo

    if [ "x${pass_user}" != "x${pass_user_again}" ] ; then
        error "user pass missmatch"
    fi
}

function get_confirmation() {
    msg=${1:-!!! This will destroy everything on device ${BOOTSTRAP_TARGET} !!!}
    warning "$msg"

    read -p "To continue type uppercase 'yes': "
    if [ "x${REPLY}" != "xYES" ] ; then
        return 1
    else
        return 0
    fi
} 

# }}}

# {{{ gitweb_ls(), gitweb_file(), gitweb_packagelist()

function gitweb_ls() {
    wget -q -O- ${REPO_WEB}/${1:-home.git}/tree/${2} | tr '\n' ' ' | grep -o '<a[^\<]*</a>' | grep 'ls-' | sed 's|.*>\(.*\)<.*|\1|g' 
}

function gitweb_file() {
    wget -q ${REPO_WEB}/${1:-home.git}/blob/${2} -O-
}

function gitweb_files() {
    for file in ${2} ; do
        wget -q ${REPO_WEB}/${1:-home.git}/blob/${file} -O-
    done
}

function gitweb_packagelist() {
    list=${1:-${BOOTSTRAP_SYSTEMTYPE}}
    lists=$( gitweb_file "home.git" ".packages/${list}.list" | grep "^\." | sed 's|^\.\ *|.packages/|g' | xargs )
    gitweb_files "home.git" ".packages/${list}.list $lists" | sed -e '/^\ *$/d' -e '/^\ *#/d' -e '/^\ *\./d' | cut -d: -f2- | xargs
}

# }}}

# {{{ check_systemtype(), check_config(), check_target_type(), check_target()

function check_systemtype() {
    gitweb_ls "home.git" ".packages" | grep -q "^${BOOTSTRAP_SYSTEMTYPE}.list$"
}

function check_config() {
    [ -z "${BOOTSTRAP_SIMON}" ] && BOOTSTRAP_SIMON=false
    [ "${BOOTSTRAP_SIMON}" != "true" ] && [ "${BOOTSTRAP_SIMON}" != "false" ] && BOOTSTRAP_SIMON=false

    [ -z "${BOOTSTRAP_RAID}" ] && BOOTSTRAP_RAID=false
    [ "${BOOTSTRAP_RAID}" != "true" ] && [ "${BOOTSTRAP_RAID}" != "false" ] && BOOTSTRAP_RAID=false

    [ "${BOOTSTRAP_SSD}" != "true" ] && [ "${BOOTSTRAP_SSD}" != "false" ] && BOOTSTRAP_SSD=false
    [ -z "${BOOTSTRAP_SSD}" ] && BOOTSTRAP_SSD=false
    
    [ "${BOOTSTRAP_SWAP}" != "true" ] && [ "${BOOTSTRAP_SWAP}" != "false" ] && BOOTSTRAP_SWAP=false
    [ -z "${BOOTSTRAP_SWAP}" ] && BOOTSTRAP_SWAP=false

    [ "${BOOTSTRAP_PACKAGES_SYSTEMTYPE}" != "true" ] && [ "${BOOTSTRAP_PACKAGES_SYSTEMTYPE}" != "false" ] && BOOTSTRAP_PACKAGES_SYSTEMTYPE=false
    [ -z "${BOOTSTRAP_PACKAGES_SYSTEMTYPE}" ] && BOOTSTRAP_PACKAGES_SYSTEMTYPE=false

    [ -z "${BOOTSTRAP_HOSTNAME}" ] && error "BOOTSTRAP_HOSTNAME empty. please configure. have a look at --help."
    [[ "$BOOTSTRAP_HOSTNAME" =~ "." ]] || warning "Configured Hostname 'BOOTSTRAP_HOSTNAME' without domain"

    [ -z "${BOOTSTRAP_SYSTEMTYPE}" ] && error "BOOTSTRAP_SYSTEMTYPE empty. please configure. have a look at --help."
    check_systemtype "${BOOTSTRAP_SYSTEMTYPE}" || error "no packagelist for systemtype '${BOOTSTRAP_SYSTEMTYPE}'"

    [ -z "${BOOTSTRAP_USERNAME}" ] && error "BOOTSTRAP_USERNAME empty. please configure. have a look at --help."

    [ -z "${BOOTSTRAP_TARGET}" ] && error "BOOTSTRAP_TARGET empty. please configure. have a look at --help."

    [ -z "${BOOTSTRAP_ARCH}" ] && error "BOOTSTRAP_ARCH empty. please configure. have a look at --help."

    [ -z "${BOOTSTRAP_SUITE}" ] && error "BOOTSTRAP_SUITE empty. please configure. have a look at --help."

    [ -z "${BOOTSTRAP_MIRROR}" ] && error "BOOTSTRAP_MIRROR empty. please configure. have a look at --help."

    [ -z "${BOOTSTRAP_COMPONENTS}" ] && error "BOOTSTRAP_COMPONENTS empty. please configure. have a look at --help."

    if ( ${BOOTSTRAP_PACKAGES_SYSTEMTYPE} ) ; then
        debug "BOOTSTRAP_PACKAGES loaded via systemtype '$BOOTSTRAP_SYSTEMTYPE'"
        BOOTSTRAP_PACKAGES="${BOOTSTRAP_PACKAGES} $( gitweb_packagelist )"
    fi
}

function check_target_type() {
    if [ -b "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=device
    elif [ -f "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=image
    elif [ -d "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=dir
    else
        error "couldn't define BOOTSTRAP_TARGET_TYPE"
    fi
} 

function check_target() {
    if [ "${BOOTSTRAP_TARGET}" = "/dev/sdX" ] ; then
        error "no target device configured. please read --help carefully and configure at least the basic settings"
    elif [ ! -e ${BOOTSTRAP_TARGET} ] ; then
        error "target device ${BOOTSTRAP_TARGET} not found"
    fi
    
    check_target_type
    debug "target device type: ${BOOTSTRAP_TARGET_TYPE}"
    
    if [ "${BOOTSTRAP_TARGET_TYPE}" = "image" ] ; then
        
        if ! ( file "${BOOTSTRAP_TARGET}" | grep -qi -e "image" -e "boot sector" ) ; then
            error "'${BOOTSTRAP_TARGET}' doesn't seem to be a valid image file"
        fi

        if ! ( lsmod | grep -qi "^nbd\ " ) ; then
            $SUDO modprobe nbd max_part=16 || error "couldn't load nbd module, but device is image"
        fi

    fi

    if [ "${BOOTSTRAP_TARGET_TYPE}" != "dir" ] ; then
        
        BOOTSTRAP_TARGET_SIZE=$( ${SUDO} parted -sm ${BOOTSTRAP_TARGET} unit mb print 2>&1 | grep -o "^${BOOTSTRAP_TARGET}:[0-9]*" | cut -f'2' -d':' )
        debug "target device size: ${BOOTSTRAP_TARGET_SIZE}MB"
        
        if [ ${BOOTSTRAP_TARGET_SIZE} -lt ${MIN_SIZE} ] ; then
            error "target device ${BOOTSTRAP_TARGET} to small. at least ${MIN_SIZE}MB are needed"
        fi

        if [ -z "${BOOTSTRAP_LAYOUT}" ] ; then
            BOOTSTRAP_LAYOUT=$( get_layout_by_size )
        fi
    
        if [ -z "${BOOTSTRAP_MOUNT}" ] ; then
            CLEANUP+=( temp_dir )
            BOOTSTRAP_MOUNT=$( mktemp -d )
            debug "temp-dir created '${BOOTSTRAP_MOUNT}'"
        fi

    else
        if [ ! -d "${BOOTSTRAP_TARGET}" ] ; then
            error "target dir '${BOOTSTRAP_TARGET}' not found"
        elif [ ! -w "${BOOTSTRAP_TARGET}" ] ; then
            error "target dir '${BOOTSTRAP_TARGET}' not writable"
        elif [ $( ls -d ${BOOTSTRAP_TARGET}/* | wc -l ) -gt 0 ] ; then
            error "target dir '${BOOTSTRAP_TARGET}' not empty"
        fi
        
        log "checking disk space on matching partition"
        free_space=$( df -m /boot/images/grml/boot/addons/bsd4grml/loopback.3 | tail -n 1 | awk {'print $4'} )
        
        if [ ${MIN_SIZE} -lt ${free_space} ] ; then
            error "target device ${BOOTSTRAP_TARGET} to small. at least ${MIN_SIZE}MB are needed"
        fi
        
        BOOTSTRAP_MOUNT=$BOOTSTRAP_TARGET
        BOOTSTRAP_LAYOUT=$( get_layout_by_size $free_space )
    fi
}

# }}}

# {{{ getFreeDevice(), partition()

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

function partition() {
    
    boot=$( get_layout ${BOOTSTRAP_LAYOUT} boot )
    swap=$( get_layout ${BOOTSTRAP_LAYOUT} swap )
    spare=$( get_layout ${BOOTSTRAP_LAYOUT} spare )
    size=$BOOTSTRAP_TARGET_SIZE
    echo "boot: ${boot} swap: ${swap} spare: ${spare} size: ${size}"

    debug "writing gpt label to target"
    $SUDO parted -s ${BOOTSTRAP_TARGET} mklabel gpt #>> log/step1.log
    
    debug "writing boot partition (${boot}mb)"
    $SUDO parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M ${boot}M #>> log/step1.log
    
    debug "writing root partition ($(( ${size} - ${swap:-0} - ${spare:-0} ))mb)"
    $SUDO parted -s ${BOOTSTRAP_TARGET} mkpart primary ${boot}M $(( ${size} - ${swap:-0} - ${spare:-0} ))M #>> log/step1.log
    
    debug "writing swap partition (${swap}mb)"
    $SUDO parted -s ${BOOTSTRAP_TARGET} mkpart primary $(( ${size} - ${swap:-0} - ${spare:-0} ))M $(( ${size} - ${spare:-0} ))M #>> log/step1.log
    
    if [ "$BOOTSTRAP_TARGET_TYPE" = 'image' ] ; then
        debug "setting sufix for image devices"
        suffix="p"
    else
        suffix=
    fi
    
    # *sigh*
    sync >/dev/null 2>&1
    $SUDO sync >/dev/null 2>&1
    $SUDO partprobe >/dev/null 2>&1
    partx -a /dev/nbd0 >/dev/null 2>&1
    $SUDO partx -a /dev/nbd0 >/dev/null 2>&1
    kpartx /dev/nbd0 >/dev/null 2>&1
    $SUDO kpartx /dev/nbd0 >/dev/null 2>&1
    
    if [ ! -e ${BOOTSTRAP_TARGET}${suffix}1 ] || [ ! -e ${BOOTSTRAP_TARGET}${suffix}2 ] || [ ! -e ${BOOTSTRAP_TARGET}${suffix}3 ] ; then
        error "at least one partition not available: $( ls ${BOOTSTRAP_TARGET}${suffix}* )" 
    fi

}


# }}}

# {{{ cleanup_trap()

function cleanup_trap() {
    echo
    cnt=$(( ${#CLEANUP[@]} - 1 ))
    for key in $( seq ${cnt} -1 0 ) ; do

        case "${CLEANUP[$key]}" in

            crypto)
                if ( $KEEP ) ; then
                    output "skipping crypto device umounts" "CLEANUP"
                else
                    output "umount ${BOOTSTRAP_MOUNT}" "CLEANUP"
                    $SUDO umount ${BOOTSTRAP_MOUNT} >/dev/null 2>&1 || warning "couldn't umount /chroot/"

                    if ( cryptsetup status /dev/mapper/install_root >/dev/null 2>&1 ) ; then
                        output "closing luks device /dev/mapper/install_root" "CLEANUP"
                        $SUDO cryptsetup luksClose /dev/mapper/install_root || warning "couldn't close luks device"
                    fi
                fi
              ;;

            chroot)
                if ( $KEEP ) ; then
                    output "skipping umounting bind mounts" "CLEANUP"
                else
                    for d in boot/ proc sys dev/pts dev/ ; do
                        output "umount ${BOOTSTRAP_MOUNT}/${d}" "CLEANUP" >/dev/null 2>&1 
                        $SUDO umount ${BOOTSTRAP_MOUNT}/${d} || warning "couldn't umount ${BOOTSTRAP_MOUNT}/${d}"
                    done
                fi
              ;;

            nbd)
                if ( $KEEP ) ; then
                    output "skipping disconnecting the nbd devices" "CLEANUP"
                else
                    output "disconnecting nbd devices" "CLEANUP"
                    for dev in $( grep -v "^0$" /sys/class/block/nbd*/size | sed 's|.*\(nbd[0-9]*\).*|/dev/\1|g' ) ; do
                        $SUDO qemu-nbd --disconnect ${dev} >/dev/null 2>&1 || warning "failed to disconnect ${dev}"
                    done
                fi
              ;;

            temp_dir)
                if ( $KEEP ) ; then
                    output "skipped deleting temp-dir '${BOOTSTRAP_MOUNT}'" "CLEANUP"
                else
                    output "deleting temp-dir '${BOOTSTRAP_MOUNT}'" "CLEANUP"
                    $SUDO rm -rf ${BOOTSTRAP_MOUNT}
                fi
              ;;

            *) error "UNKNOWN CLEANUP KEY: ${CLEANUP[$key]}" ;;

        esac
    done

}

# }}}

# {{{ main 

log "Starting Bootstrap"
depends "wget" || error "depends 'wget' missing"

# {{{ getopts

for arg ; do
    delim=""
    case "$arg" in
        --help)    args="${args}-h " ;;
        --verbose) args="${args}-v " ;;
        --nocolor) args="${args}-n " ;;
        --config)  args="${args}-c " ;;
        --keep)    args="${args}-k " ;;
        
        # pass through anything else
        *) [[ "${arg:0:1}" == "-" ]] || delim="\""
            args="${args}${delim}${arg}${delim} ";;
    esac
done

eval set -- "$args"
while getopts ":hvnkc" opt ; do
    case $opt in
        h|\?) USAGE=true ;;
        v)  VERBOSE=true ;;
        n)  NOCOLOR=true ;;
        c)  CONFIG=true ;;
        k)  KEEP=true ;;
        *)  error "Unknown option: '$opt'"
    esac
done

if ( $USAGE ) ; then
    usage
elif ( $CONFIG ) ; then
    echo "Settings at the moment:"
    settings | sed 's|^|\t|g'
    echo 
    exit 0 
fi

# }}}

eval "$( gitweb_file 'home.git' '.lib/resources.sh' | grep -v '^#' )"

if ( $NOCOLOR ) ; then
    debug "disabled coloring"
else
    COLORING=true
    debug "activated coloring"
fi

check_sudo

for dep in ${DEPENDS} ; do
    depends "${dep}" || error "depends '${dep}' missing"
done

for dep in ${DEBIAN_DEPENDS} ; do
    depends "${dep}" "debian" || error "depends '${dep}' missing"
done

check_config
check_target

if ( ! $VERBOSE ) ; then
    get_credentials
    get_confirmation || error "Canceled by user"
fi

settings | while read i ; do
    log "${i}"
done

debug "starting cleanup_trap"
trap cleanup_trap EXIT

if [ "${BOOTSTRAP_TARGET_TYPE}" != 'dir' ] ; then
    partition
    #todo: mount
fi

#todo: bootstrap

if ( ${BOOTSTRAP_SIMON} ) ; then
    echo
    #todo: repos, ...
fi

#todo: system

log "Bootstrap Completed"
exit 0

# }}}

# {{{ init, includes, depends

#BOOTSTRAP_TARGET_ORIG=${BOOTSTRAP_TARGET}
#BOOTSTRAP_TARGET="/dev/nbd$( getFreeDevice nbd )"
#$SUDO qemu-nbd -c ${BOOTSTRAP_TARGET} ${BOOTSTRAP_TARGET_ORIG}
#CLEANUP+=( "nbd" )
#debug "device '${BOOTSTRAP_TARGET}' -> '${BOOTSTRAP_TARGET_ORIG}'"

debug "format '/boot' as ext3"
$SUDO mkfs.ext3 -q -F -L boot ${BOOTSTRAP_TARGET}${suffix}1 >/dev/null 2>&1 || error "failed to format /boot"

CLEANUP+=( "crypto" )
log "crypting root"
echo -ne "$pass_phrase" | $SUDO cryptsetup -q luksFormat ${BOOTSTRAP_TARGET}${suffix}2 - >/dev/null 2>&1 || error "luksformat failed"
[ -e /dev/mapper/install_root ] && error "/dev/mapper/install_root is already in use"
echo -ne "$pass_phrase" | $SUDO cryptsetup luksOpen ${BOOTSTRAP_TARGET}${suffix}2 install_root - || error "couldn't open luks device"

debug "format '/' as btrfs"
$SUDO mkfs.btrfs -f -L root /dev/mapper/install_root >/dev/null 2>&1 || error "failed to format /root"

debug "creating 'swap'"
$SUDO mkswap -L swap ${BOOTSTRAP_TARGET}${suffix}3 >/dev/null 2>&1 || warning "failed to create swap"

# }}}

# {{{ mount stuff

CLEANUP+=( "chroot" )

$SUDO mkdir -p ${BOOTSTRAP_MOUNT}
$SUDO mount /dev/mapper/install_root ${BOOTSTRAP_MOUNT} || error "couldn't mount root"

$SUDO mkdir -p ${BOOTSTRAP_MOUNT}/boot/
$SUDO mount ${BOOTSTRAP_TARGET}${suffix}1 ${BOOTSTRAP_MOUNT}/boot/ || error "couldn't mount boot"

# }}}

# {{{ bootstrap

BOOTSTRAP_PACKAGES="$packages grub2 grub-pc"
if [ "${BOOTSTRAP_ARCH}" = "amd64" ] ; then
    BOOTSTRAP_PACKAGES="$packages linux-image-3.16-3-amd64"
else
    BOOTSTRAP_PACKAGES="$packages linux-image-3.16-3-686-pae"
fi

[ -n "${BOOTSTRAP_PACKAGES}" ] && packages="--include=$( echo ${BOOTSTRAP_PACKAGES} | sed 's|\ |,|g')" || packages=""
[ -n "${BOOTSTRAP_COMPONENTS}" ] && components="--components=${BOOTSTRAP_COMPONENTS}" || components=""

log "starte bootstrapping"
debug "$SUDO debootstrap --arch ${BOOTSTRAP_ARCH} ${packages} ${components} ${BOOTSTRAP_SUITE} ${BOOTSTRAP_MOUNT} ${BOOTSTRAP_MIRROR}"
( ! $VERBOSE ) && out=">/dev/null"
$SUDO debootstrap ${packages} ${components} ${BOOTSTRAP_SUITE} ${BOOTSTRAP_MOUNT} ${BOOTSTRAP_MIRROR} $out || error "bootstrap failed"
log "bootstrapping successfull"

# }}}

# {{{ prepare chroot

for dir in /dev/ /dev/pts /sys/ /proc/ ; do
    debug "bind-mount ${dir} -> ${BOOTSTRAP_MOUNT}${dir}"
    [ ! -e ${BOOTSTRAP_MOUNT}${dir} ] && $SUDO mkdir -p ${BOOTSTRAP_MOUNT}${dir}
    $SUDO mount -o bind ${dir} ${BOOTSTRAP_MOUNT}${dir} || error "couldn't bind-mount ${dir}"
done

# }}}

# {{{ system

#todo: use UUID!
# uuid=$( blkid /dev/sda1 | sed 's|^.*uuid="\([0-9A-Z]*\)".*$|\1|Ig' )
echo ">>> Creating /etc/fstab"
#echo -e "${BOOTSTRAP_TARGET}1\t/boot\text3\tdefault\t0 0" > ${BOOTSTRAP_MOUNT}/etc/fstab
#echo -e "/dev/mapper/root\t/\tbtrfs\tautodefrag,noatime,rw,ssd,compress,thread_pool=32\t0 0" >> ${BOOTSTRAP_MOUNT}/etc/fstab

#todo: use UUID!
echo ">>> Creating /etc/crypttab"
#echo -e "root\t${BOOTSTRAP_TARGET}2\tnone\tluks" > ${BOOTSTRAP_MOUNT}/etc/crypttab

#echo ">>> Creating default User '${BOOTSTRAP_USERNAME}'"
#useradd -m -U -s /bin/bash ${BOOTSTRAP_USERNAME}

#echo ">>> Changing password for User '${BOOTSTRAP_USERNAME}'"
#passwd ${BOOTSTRAP_USERNAME}
# do it so: echo username:new_password | chpasswd
#adduser --quiet --disabled-password -shell /bin/bash --home /home/${BOOTSTRAP_USERNAME} --no-create-home ${BOOTSTRAP_USERNAME}
#echo "${BOOTSTRAP_USERNAME}:${pass_user}" | chpasswd

#echo ">>> Changing password for User 'root'"
#passwd root

#echo ">>> Setting up apt (better use hook)"
#echo 'deb http://security.debian.org/ testing/updates main contrib non-free' > /etc/apt/sources.list
#echo 'deb http://ftp2.de.debian.org/debian testing main contrib non-free' >> /etc/apt/sources.list
#apt-get update

#echo ">>> Installing Kernel and Bootloader (better use hook)"
#apt-get install grub2 linux-image-2.6-686-pae linux-headers-2.6-686-pae firmware-linux-free firmware-linux-nonfree firmware-realtek firmware-iwlwifi

#groups="audio video plugdev netdev fuse sudo"
#echo ">>> Adding User '${BOOTSTRAP_USERNAME}' to default groups:"
#echo "> $groups"
#for group in $groups
#do
#    usermod -a -G ${group} ${BOOTSTRAP_USERNAME}
#done

#echo ">>> Setting minimal permissions (better use hook)"
#chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME} -R
#find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;

#echo ">>> Setting up locales"
#echo "set locales/default_environment_locale de_DE.UTF-8" | sudo debconf-communicate
#echo "set locales/locales_to_be_generated de_DE.UTF-8 UTF-8" | sudo debconf-communicate
#dpkg-reconfigure -f noninteractive locales

#echo ">>> Reconfiguring Debconf"
#echo "set debconf/frontend Dialog" | sudo debconf-communicate
#echo "set debconf/priority high" | sudo debconf-communicate
#dpkg-reconfigure -f noninteractive debconf

#echo ">>> Setting up keyboard (via debconf)"
#echo "set keyboard-configuration/layout German" | sudo debconf-communicate
#echo "set keyboard-configuration/variant German - German (eliminate dead keys)" | sudo debconf-communicate
#dpkg-reconfigure -f noninteractive keyboard-configuration

#echo ">>> Setting clock/timezone"
#echo "set tzdata/Areas Europe" | sudo debconf-communicate
#echo "set tzdata/Zones/Etc UTC" | sudo debconf-communicate
#echo "set tzdata/Zones/Europe Berlin" | sudo debconf-communicate
#dpkg-reconfigure -f noninteractive tzdata
#hwclock --utc
#ntpdate time.fu-berln.de
#hwclock --systohc

# }}}

