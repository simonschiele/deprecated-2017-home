#!/bin/bash
#
# Simon Schiele (simon.codingmonkey@googlemail.com)
#

function load_cleanup_trap() {
    msg "loading cleanup() trap"
    trap cleanup_trap EXIT
}

function cleanup() {
    # todo: clean only what wasn't enabled via env
    unset BOOTSTRAP_ARCH BOOTSTRAP_COMPONENTS BOOTSTRAP_DOMAINNAME \
          BOOTSTRAP_HOSTNAME BOOTSTRAP_PACKAGES BOOTSTRAP_PROXY \
          BOOTSTRAP_REPOSITORY BOOTSTRAP_SUITE BOOTSTRAP_TARGET_DEVICE \
          BOOTSTRAP_TARGET BOOTSTRAP_TYPE BOOTSTRAP_USERNAME CMD CONFIG \
          DEPENDS FILE KEEP LOGFILE LOGLEVEL NOCOLOR SCRIPTDIR SCRIPTNAME \
          SILENT HELP VERBOSE DEBIAN_FRONTEND
}

function load_defaults() {
    set -e
    LANG=C

    SCRIPTNAME=$( basename "$0" )
    SCRIPTDIR=$( dirname "$( readlink -f "$0" )" )
    DEPENDS=( wget parted debootstrap cryptsetup git sudo )
    DEPENDS_DEBIAN=""

    HELP=${HELP:-false}
    VERBOSE=${VERBOSE:-false}
    SILENT=${SILENT:-false}
    NOCOLOR=${NOCOLOR:-false}
    KEEP=${KEEP:-false}
    CONFIG=${CONFIG:-false}
    LOGFILE=${LOGFILE:-bootstrap.log}
    LOGLEVEL=${LOGLEVEL:-debug}

    BOOTSTRAP_ARCH=${BOOTSTRAP_ARCH:-amd64}
    BOOTSTRAP_COMPONENTS=${BOOTSTRAP_COMPONENTS:-main,contrib,non-free}
    BOOTSTRAP_DOMAINNAME=${BOOTSTRAP_DOMAINNAME:-psaux.de}
    BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME:-}
    BOOTSTRAP_PACKAGES=${BOOTSTRAP_PACKAGES:-bash,git,wget,ca-certificates,locales,console-setup,keyboard-configuration}
    BOOTSTRAP_PROXY=${BOOTSTRAP_PROXY:-}
    BOOTSTRAP_REPOSITORY=${BOOTSTRAP_REPOSITORY:-ftp.de.debian.org/debian/}
    BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE:-testing}
    BOOTSTRAP_TYPE=${BOOTSTRAP_TYPE:-workstation}
    BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME:-${SUDO_USER:-$USER}}

    BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET:-}
    BOOTSTRAP_TARGET_DEVICE=${BOOTSTRAP_TARGET_DEVICE:-}

    DEBIAN_FRONTEND=noninteractive

    verify_packagelist
    PACKAGES=$( grep -o "^[^\#]\+#*" "$HOME/.packages_$BOOTSTRAP_TYPE" | sed 's|#.*||g' | xargs )

    declare -A FILE
    FILE[log]=bootstrap.log

    declare -A CMD
    CMD[apt-install]='apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'
    CMD[apt-update]='apt-get update -q'
    CMD[chroot]=''
    CMD[sudo]=''
}

function load_opts() {
    for arg ; do
        delim=""
        case "$arg" in
            --logfile) args="${args}-l " ;;
            --loglevel) args="${args}-L " ;;
            --config) args="${args}-c " ;;
            --help) args="${args}-h " ;;
            --keep) args="${args}-k " ;;
            --nocolor) args="${args}-n " ;;
            --silent) args="${args}-s " ;;
            --verbose) args="${args}-v " ;;

            # pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
    done

    eval set -- "$args"
    while getopts ":chknsvlL" opt ; do
        case $opt in
            L) LOGLEVEL=true ;;
            c) CONFIG=true ;;
            h|\?) HELP=true ;;
            k) KEEP=true ;;
            l) LOGFILE=true ;;
            n) NOCOLOR=true ;;
            s) SILENT=true ;;
            v) VERBOSE=true ;;
            *) error "Unknown option: '$opt'"
        esac
    done
}

function show_config() {
    if ( $VERBOSE ) ; then
        echo
        echo "Config at the moment:"
        echo
        echo " [Application Config]"
    fi
    set | grep "^LOGLEVEL\|^CONFIG\|^HELP\|^KEEP\|^NOCOLOR\|^SILENT\|^VERBOSE\|^LOGFILE" | sort | sed 's|^|  |g'

    if ( $VERBOSE ) ; then
        echo
        echo " [Bootstrap Config]"
    fi
    set | grep "^BOOTSTRAP" | sort | sed 's|^|  |g'

    exit 0
}

function show_help() {
    echo
    echo "$SCRIPTNAME [options] <directory|device> [directory]"
    echo
    echo "Application Options:"
    echo " -c | --config        | show config values"
    echo " -h | --help          | this info"
    echo " -k | --keep          | dont't umount chroot and don't delete tmpDir"
    echo " -n | --nocolor       | disable coloring"
    echo " -s | --silent        | silent mode (no in-/output at all)"
    echo " -v | --verbose       | activate verbose mode"
    echo
    echo "Bootstrap Options:"
    echo " --bootstrap-arch [amd64|i386|...]"
    echo " --bootstrap-components [main,contrib,non-free,...]"
    echo " --bootstrap-domainname [psaux.de|cnet.loc|fritz.box|...]"
    echo " --bootstrap-hostname [cpad|cstation|cbase|...]"
    echo " --bootstrap-packages [bash,git,wget,ca-certificates,locales,console-setup,keyboard-configuration,...]"
    echo " --bootstrap-proxy [localhost:3142|...]"
    echo " --bootstrap-repository [ftp.de.debian.org/debian/|...]"
    echo " --bootstrap-suite [testing|unstable|stable|...]"
    echo " --bootstrap-type [server|workstation|laptop]"
    echo " --bootstrap-username [simon|sschiele|...]"
    echo " --bootstrap-target [test23/|/tmp/deb_testing|...]"
    echo " --bootstrap-target-device [/dev/sdc|sde|600515af-2ee9-41f1-9c2d-0065f8c1a526|...]"
    echo
    echo "All options can also be set as an environment variable:"

    if ( $VERBOSE ) ; then
        echo " > BOOTSTRAP_PROXY=localhost:3142 $SCRIPTNAME -c"
        echo " > BOOTSTRAP_PROXY=localhost:3142 BOOTSTRAP_USERNAME=simon $SCRIPTNAME -v -k"
        echo
        echo " > export BOOTSTRAP_PROXY=localhost:3142"
        echo " > export BOOTSTRAP_SUITE=unstable"
        echo " > export VERBOSE=true"
        echo " > export NOCOLOR=true"
        echo " > $SCRIPTNAME"
        echo
        echo "The order of the config parsing (first to last):"
        echo " * default config"
        echo " * environment variables"
        echo " * command line arguments"
        echo
        echo "So this would result in a debian testing installation:"
        echo " > BOOTSTRAP-SUITE=unstale $SCRIPTNAME --bootstrap-suite testing"
    else
        echo " > export VERBOSE=true BOOTSTRAP_PROXY=localhost:3142"
        echo " > $SCRIPTNAME -c"
        echo
        echo "To list available bootstrap-types and options, call in verbose mode:"
        echo " > $SCRIPTNAME --help --verbose"
    fi

    if ( $CONFIG ) ; then
        show_config
    else
        echo
        echo "To see the actual config as it is set at the moment, use the --config flag:"
        echo " > $SCRIPTNAME --config"
        echo
        echo "Verify your configuration with a combination of verbose, help and config flag for all details:"
        echo " > $SCRIPTNAME -v -h -c"
    fi

    exit 0
}

function verify_packagelist() {
    local packagelist="$HOME/.packages_$BOOTSTRAP_TYPE"

    if [[ ! -r "$packagelist" ]] ; then
        error_exit "Couldn't open or find package list '$packagelist'"
    elif ! ( grep -q "^[A-Za-z]" "$packagelist" ) ; then
        error_exit "Package list '$packagelist' is empty or invalid"
    fi
}

function verify_opts() {
    if ( $HELP ) ; then
        show_help
    elif ( $CONFIG ) ; then
        show_config
    fi
}

function verify_depends() {
    local dep

    for dep in ${DEPENDS[*]} ; do
        which "${dep}" || error_exit "Please install depends: '$dep'"
    done
}

function verify_config() {
    error "Unimplemented" "verify_config() (skipped)"
}

function prepare_target_device() {
    msg "Partitioning $BOOTSTRAP_TARGET_DEVICE (skipped)"
    #gparted $BOOTSTRAP_TARGET_DEVICE

    msg "Format /boot/ (skipped)"
    #mkfs.ext3 -L boot ${BOOTSTRAP_TARGET_DEVICE}1

    msg "Format root (skipped)"
    #mkfs.ext4 -L root ${BOOTSTRAP_TARGET_DEVICE}2

    msg "Format swap (skipped)"
    #mkswap -L swap ${BOOTSTRAP_TARGET_DEVICE}3

    msg "Enable swap (skipped)"
    #swapon ${BOOTSTRAP_TARGET_DEVICE}3

    msg "Mount root (skipped)"
    #mount ${BOOTSTRAP_TARGET_DEVICE}2 $BOOTSTRAP_TARGET

    error "Unimplemented" "prepare_target_device() (skipped)"
}

function prepare_target() {
    if [ -b "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=device
    elif [ -f "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=image
    elif [ -d "${BOOTSTRAP_TARGET}" ] ; then
        BOOTSTRAP_TARGET_TYPE=dir
    else
        error "Unknown BOOTSTRAP_TARGET_TYPE"
    fi

    case "$BOOTSTRAP_TARGET_TYPE" in
        dir)
            msg "Preparing target '$BOOTSTRAP_TARGET/'"
            if [ -e "$BOOTSTRAP_TARGET" ] ; then
                seq 1 10 | while read i ; do
                    mount | grep "$BOOTSTRAP_TARGET" | awk '{print $3}' | while read j ; do
                        msg "umount '$j'"
                        umount "$j" >/dev/null 2>&1
                    done
                done

                if mount | grep -q "$BOOTSTRAP_TARGET" ; then
                    error_exit "Couldn't unmount '$BOOTSTRAP_TARGET'"
                fi

                if ! rm -rf "$BOOTSTRAP_TARGET" ; then
                    error_exit "Couldn't remove '$BOOTSTRAP_TARGET'"
                fi
            fi

            if ! mkdir -p "$BOOTSTRAP_TARGET" ; then
                error_exit "Couldn't create '$BOOTSTRAP_TARGET'"
            fi
            ;;

        *)
            error_exit "Target Type '$BOOTSTRAP_TARGET_TYPE' not implemented yet"
    esac
}

function setup_bootstrap() {
    msg "Bootstrap (might take a while...)"
    debootstrap --components="$BOOTSTRAP_COMPONENTS" \
                --arch="$BOOTSTRAP_ARCH" \
                --include="$BOOTSTRAP_PACKAGES" \
                "$BOOTSTRAP_SUITE" \
                "$BOOTSTRAP_TARGET" \
                "http://${BOOTSTRAP_PROXY:+$BOOTSTRAP_PROXY/}$BOOTSTRAP_REPOSITORY"
}

function setup_chroot() {
    msg "bind-mounts"
    for i in sys proc dev dev/pts ; do
        mount --bind /"$i" "$BOOTSTRAP_TARGET"/"$i" || error_exit "Couldn't do bind mount for '$i'"
    done
}

function setup_etc() {
    msg "Install/Setup etckeeper"
    LANG=C chroot "$BOOTSTRAP_TARGET"/ ${CMD[apt-install]} etckeeper

    msg "Setup locales"
    sed -i 's|.*\(de_DE.UTF-8\)|\1|g' "$BOOTSTRAP_TARGET"/etc/locale.gen
    sed -i 's|.*\(en_US.UTF-8\)|\1|g' "$BOOTSTRAP_TARGET"/etc/locale.gen
    sed -i 's|.*\(en_GB.UTF-8\)|\1|g' "$BOOTSTRAP_TARGET"/etc/locale.gen
    chroot "$BOOTSTRAP_TARGET" locale-gen
    chroot "$BOOTSTRAP_TARGET" update-locale LANG=en_GB.UTF-8 LC_MESSAGES=POSIX

    msg "Setup keyboard"
    (
        echo "# KEYBOARD CONFIGURATION FILE"
        echo "# Consult the keyboard(5) manual page."
        echo
        echo 'XKBMODEL="pc105"'
        echo 'XKBLAYOUT="de"'
        echo 'XKBVARIANT="nodeadkeys"'
        echo 'XKBOPTIONS=""'
        echo
        echo 'BACKSPACE="guess"'
    ) > "$BOOTSTRAP_TARGET"/etc/default/keyboard
    chroot "$BOOTSTRAP_TARGET" udevadm trigger --subsystem-match=input --action=change

    msg "Setup timezone"
    echo "Europe/Berlin" > "$BOOTSTRAP_TARGET"/etc/timezone

    msg "Setup /etc/hostname"
    echo "$BOOTSTRAP_HOSTNAME.$BOOTSTRAP_DOMAINNAME" > "$BOOTSTRAP_TARGET"/etc/hostname

    msg "Setup /etc/hosts"
    (
        echo "127.0.0.1        localhost $BOOTSTRAP_HOSTNAME $BOOTSTRAP_HOSTNAME.$BOOTSTRAP_DOMAINNAME localhost.localdomain"
        echo
        echo "::1              ip6-localhost ip6-loopback"
        echo "ff02::1          ip6-allnodes"
        echo "ff02::2          ip6-allrouters"
        echo
        echo "# workstation p'berg"
        echo "192.168.91.72      simon-work work"
    ) > "$BOOTSTRAP_TARGET"/etc/hosts

    msg "Setup /etc/apt/"
    rm -f "$BOOTSTRAP_TARGET"/etc/apt/sources.list
    debian.source.list "$BOOTSTRAP_SUITE" > "$BOOTSTRAP_TARGET"/etc/apt/sources.list
    debian.source.list "thirdparty" > "$BOOTSTRAP_TARGET"/etc/apt/sources.list.d/thirdparty.list
    chroot "$BOOTSTRAP_TARGET" chown root: /etc/apt/sources.list /etc/apt/sources.list.d/ -R
    chroot "$BOOTSTRAP_TARGET" chmod 644 /etc/apt/sources.list /etc/apt/sources.list.d/ -R
    chroot "$BOOTSTRAP_TARGET" ${CMD[apt-update]}

    msg "etckeeper commit"
    chroot "$BOOTSTRAP_TARGET" etckeeper commit bootstrap_base_config

    msg "Install stuff from ~/.packages_$BOOTSTRAP_TYPE"
    chroot "$BOOTSTRAP_TARGET" ${CMD[apt-install]} "$PACKAGES"

    msg "Checking out home-repo"
    git clone https://github.com/simonschiele/home.git "$BOOTSTRAP_TARGET"/home/simon/

    msg "Copy dot.wallpapers"
    cp -r ~/.wallpapers/ "$BOOTSTRAP_TARGET"/home/simon/.wallpapers

    msg "Copy dot.fonts"
    cp -r ~/.fonts/ "$BOOTSTRAP_TARGET"/home/simon/.fonts

    msg "Copy dot.private"
    cp -r ~/.private/ "$BOOTSTRAP_TARGET"/home/simon/.private

    msg "Setting symlinks"
    ln -s .private/work "$BOOTSTRAP_TARGET"/home/simon/.work
    ln -s .work "$BOOTSTRAP_TARGET"/home/simon/.pb
    # ln -s .lib/solarized/xresources/solarized "$BOOTSTRAP_TARGET"/home/simon/.Xresources

    msg "Populate /media/"
    mkdir -p "$BOOTSTRAP_TARGET"/media/{usb,image}{1..4}

    msg "Copy /etc/sudoers.d/$BOOTSTRAP_TYPE"
    cp /etc/sudoers.d/"$BOOTSTRAP_TYPE" "$BOOTSTRAP_TARGET/etc/sudoers.d/$BOOTSTRAP_TYPE"

    error "Unimplemented" "Setting up /etc/default/console-setup (skipped)"
    error "Unimplemented" "Fixing Permissions (skipped)"
    error "Unimplemented" "Setting up /etc/nsswitch (skipped)"
    error "Unimplemented" "Setting up LUKS (skipped)"
}

function setup_boot() {
    msg "mount /boot/ (skipped)"
    #mount ${BOOTSTRAP_TARGET_DEVICE}1 /mnt/boot

    error "Unimplemented" "Setting up grub2 (skipped)"
    error "Unimplemented" "Setting up SplashScreen (skipped)"
    error "Unimplemented" "Setting up grml/liveboot (skipped)"
}

function setup_home() {
    # sudo chown simon: ~/ -R ; find -name index\.lock -delete ; git submodule update --init --recursive ; git submodule foreach --recursive git fetch ; git submodule foreach git merge origin master
    error "Unimplemented" "setup_home() (skipped)"
}

function setup_home_root() {
    error "Unimplemented" "setup_home_root() (skipped)"
}

function setup_user() {
    error "Unimplemented" "setup_user() (skipped)"
}

function install_software() {
    error "Unimplemented" "Installing Skype (skipped)"
    error "Unimplemented" "Installing non-free firmware (skipped)"
    error "Unimplemented" "Installing non-free firmware - gobi (skipped)"
    error "Unimplemented" "install_software() (skipped)"
}

function setup_software() {
    error "Unimplemented" "setup_software() (skipped)"
}

function log() {
    # logger
    error "Unimplemented" "log() (skipped)"
}

function msg() {
    local msg_type message
    msg_type="${2:+$1:}"
    message="${2:-$1}"
    echo "> ${msg_type:+$msg_type }$message"
}

function error() {
    local error_type message
    error_type=${2:+$1}
    message=${2:-$1}
    msg "${error_type:-Error}: $message" >&2
}

function error_exit() {
    error "$*"
    exit 1
}

function bootstrap() {
    load_cleanup_trap
    load_defaults
    load_opts "$@"

    verify_opts
    verify_depends
    verify_config

    prepare_target_device
    prepare_target

    setup_bootstrap
    setup_chroot
    setup_boot
    setup_etc
    setup_home
    setup_user
    setup_home_root

    install_software
    setup_software
}

# clean sh example
# https://stuff.mit.edu/afs/athena/system/i386_deb50/os-ubuntu-9.04/usr/sbin/debootstrap

# example with bootstrap from git
# /usr/share/doc/debootstrap/README

# logger --stderr --> log + print erros

# log + print everything
# bootstrap "$@" 2>&1 | tee -a "$LOG"

# log everything - print errors
# bootstrap "$@" 2>&1 >> "$LOG" | tee -a "$LOG"

bootstrap "$@"
