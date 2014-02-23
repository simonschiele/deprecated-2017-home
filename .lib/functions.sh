#!/bin/bash

# {{{ compress()

compress() {
    local OLDOPTIND=$OPTIND 
    local HELP=false
    local DATE=false
    local VERBOSE=''
    local ERROR='' 
    
    while getopts ":hdv" opt ; do
        case $opt in
            h)
                HELP=true
                ;;
            d)
                DATE=true
                ;;
            v)
                VERBOSE=true
                ;;
            \?)
                ERROR="Unknown Flag: -$OPTARG"
                ;;
        esac
    done
    shift $((OPTIND-1))
    OPTIND=$OLDOPTIND
   
    ! ${HELP} && [ -z "${ERROR}" ] && ([ -z "${1}" ] || [ -z "${2}" ]) && \
        ERROR="Please give at least a type of archive and what to compress"

    $HELP || [ -n "${ERROR}" ] && \
        echo "${FUNCNAME} [-h] [-d] <rar|zip|file.tar.gz> <dir/> [<data.txt|data2/>]"
    
    [ -n "$ERROR" ] && echo ${ERROR} && return 1
    $HELP && return 0

        ( [ -n "${ERROR}" ] && return 1 || return 0 )
   
    local target="${1}"
    local content="${2}"
    shift
    
    local archivetype="${target##*.}" 
    local change_dir=false
    
    if [ "$( basename ${content} )" == "." ]
    then
        content=$( basename "$( pwd )" | sed 's|\ |\\ |g' )
        change_dir=true
    else
        content="$@"
    fi

    [ $change_dir ] && cd ..

    local status=true
    case "${archivetype,,}" in
        rar)
            archivetype="rar"
            local cmd="rar a -ol -r -ow -idc $( ! [ ${VERBOSE} ] && echo '-inul' ) --"
            ;;
        zip)
            archivetype="zip"
            local cmd="zip -r -y $( ! [ ${VERBOSE} ] && echo '-q' )"
            ;;
        bzip2|bz2)
            archivetype="tar.bz2"
            local cmd="tar cjf${VERBOSE:+v}"
            ;;
        tar|gz|targz|tgz)
            archivetype="tar.gz"
            local cmd="tar czf${VERBOSE:+v}"
            ;;
        *)
            echo "Archivformat '${archivetype}' is not supported" && status=false
            ;;
    esac
    
    if [ "${archivetype}" == "${target}" ] || ! ( echo "$target" | grep -q "\." )
    then
        [ -n "${2}" ] && echo "Autonaming is only supported if you compress only one file or directory" && return 1
        local cleancontent=$( basename ${content} | sed -e 's|^\.|dot.|g' )
        target="${cleancontent%.*}.${archivetype}"
    fi
    
    $status && $cmd $target $content
    
    [ $change_dir ] && cd "${OLDPWD}"

    return $( $status )
}

# }}}

# {{{ worldclock()

worldclock() { 
    zones="America/Los_Angeles America/Chicago America/Denver America/New_York Europe/London"
    zones="${zones} Europe/Paris Europe/Berlin Europe/Moscow Asia/Hong_Kong Australia/Sydney"

    for tz in $zones 
    do 
        local tz_short=$( echo ${tz} | cut -f'2' -d'/' )
        echo -n -e "${tz_short}\t"
        [[ ${#tz_short} -lt 8 ]] && echo -n -e "\t"
        TZ=${tz} date
        #echo -e "$( echo ${d} | cut -d'/' -f'2' )$([ ${#d} -lt 11 ] && echo -e '\t')\t\t$( date )"
    done
    unset tz
}

# }}}

# {{{ debian_packages_list()

debian_packages_list() {
    local listtype="${1}.list"
    local pkglist="${HOME}/.packages/${listtype}"

    if ! [ -e $pkglist ] || [ -z "${@}" ]
    then
        echo "Unknown Systemtype '$pkglist'"
        return 1
    fi
    
    local lists="$listtype $(grep ^[\.] $pkglist | sed 's|^[\.]\ *||g')"
    lists=$( echo $lists | sed "s|\([A-Za-z0-9]*\.list\)|${HOME}/.packages/\1|g" )

    sed -e '/^\ *$/d' -e '/^\ *#/d' -e '/^[\.]/d' $lists | cut -d':' -f'2-' | xargs
}

# }}}

# {{{ convert2()

convert2() {
    ext=${1} ; shift ; for file ; do echo -n ; [ -e "$file" ] && ( echo -e "\n\n[CONVERTING] ${file} ==> ${file%.*}.${ext}" && ffmpeg -loglevel error -i "${file}" -strict experimental "${file%.*}.${ext}" && echo rm -i "${file}" ) || echo "[ERROR] File not found: ${file}" ; done
}

# }}}

# {{{ keyboard_kitt()

function keyboard_kitt() {
	# copyright 2007 - 2010 Christopher Bratusek
	setleds -L -num;
	setleds -L -caps;
	setleds -L -scroll;
	while :; do
		setleds -L +num;
		sleep 0.2;
		setleds -L -num;
		setleds -L +caps;
		sleep 0.2;
		setleds -L -caps;
		setleds -L +scroll;
		sleep 0.2;
		setleds -L -scroll;
		setleds -L +caps;
		sleep 0.2;
		setleds -L -caps;
	done
	resetleds
}

# }}}

# {{{ confirm()

confirm() {
    if [ "x${@}" == "x" ]
    then
        message="Are you sure you want to perform 'unknown action'?"
    else
        message="${@}"
    fi

    whiptail --yesno "${message}" 10 60
}

# }}}

# {{{ spinner(), spinner_result()

function spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

function spinner_result() {
    (
        tmp_pid=${BASHPID}
        spinner ${tmp_pid} &
        $( ${@} >/dev/null )
        kill ${tmp_pid}
        wait ${tmp_pid} 2>/dev/null
    )
}

# }}}

# {{{ good_morning()

function good_morning() {
    sudo echo -n
    #( sleep 3 & )
    #spinner $!
    echo -n -e ">>> updating debian package lists: " && spinner_result "sudo apt-get update"
    #echo -e ">>> installing default packages: " #&& if [ -e ~/.system.conf ] ; then sudo apt-get install $( debian_packages_list $( grep -i systemtype .system.conf | sed -e 's|\(.*\)="\(.*\)"|\2|g' )) ; else echo -e "system.conf missing!" ; fi
    #echo -e ">>> system upgrade: " #&& sudo apt-get dist-upgrade
    #echo -n -e "\n>>> updating home: " && silent_result "cd /home/${SUDO_USER:-$USER}/ && git pull && git submodule init && git submodule update && cd ${OLDPWD}"
    #echo -e ">>> system status: $( w )"
    #echo && cal && echo -e "\nToday: $( date )\n"
    #echo -e "\n\nGood Morning Simon! Have a wonderful day!\n\n"
}

# }}}

# {{{ random_integer()

function random_integer() {
    if [ -n "${2}" ]
    then
        local from=${1}
        local to=${2}
    else
        local from=1
        local to=${1:-100}
    fi

    echo $(( RANDOM % ${to}+ ${from} ))
}

# }}}

# {{{ whereami()
function whereami() {
    ips=$( /sbin/ifconfig | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -u | grep -v -e "^127" -e "^255" )
    if ( echo $ips | grep -q -e "192\.168\.[78]0" ) ; then
        echo "work"
    elif ( echo $ips | grep -q -e "192\.168\.5" ) ; then
        echo "home"
    else
        echo "unknown"
    fi
}

# }}}

