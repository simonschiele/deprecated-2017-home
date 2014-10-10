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
    zones="America/Los_Angeles America/Chicago America/Denver America/New_York Iceland Europe/London"
    zones="${zones} Europe/Paris Europe/Berlin Europe/Moscow Asia/Hong_Kong Australia/Sydney"

    for tz in $zones 
    do 
        local tz_short=$( echo ${tz} | cut -f'2' -d'/' )
        echo -n -e "${tz_short}\t"
        [[ ${#tz_short} -lt 8 ]] && echo -n -e "\t"
        TZ=${tz} date
    done
    unset tz zones
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
    if ( echo $ips | grep -q -e "192\.168\.[78]0" -e "195\.4\.7[01]" ) ; then
        echo "work"
    elif ( echo $ips | grep -q -e "192\.168\.5" ) ; then
        echo "home"
    else
        echo "unknown"
    fi
}

# }}}

# {{{ verify_su()

function verify_su() {
    if [ "$( id -u )" == "0" ] ; then
        return 0 
    elif ( sudo echo -n ) ; then
        return 0
    else
        return 1
    fi
}

# }}} 

# {{{ debian_add_pubkey()

function debian_add_pubkey() {
    if ! verify_su ; then
        echo "you need root/sudo permissions to call debian_add_pubkey" 1>&2 
        return 1
    elif [ -z "${1}" ] ; then
        echo "Please call like:"
        echo " > debian_add_pubkey path/to/file.key" 
        echo "or"
        echo " > debian_add_pubkey 07DC563D1F41B907" 
    elif [ -e ${1} ] ; then
        echo "import via keyfile not implemented yet" 1>&2 
        return 1
    else
        if ( gpg --keyserver pgpkeys.mit.edu --recv-key ${1} ) && ( gpg -a --export ${1} | sudo apt-key add - ) ; then
            return 0
        else
            return 1
        fi
    fi
}

# }}} 

# {{{ google()

function google() {
    Q="$@";
    GOOG_URL='https://www.google.com/search?tbs=li:1&q=';
    AGENT="Mozilla/4.0";
    stream=$(curl -A "$AGENT" -skLm 10 "${GOOG_URL}${Q//\ /+}");
    echo "$stream" | grep -o "href=\"/url[^\&]*&amp;" | sed 's/href=".url.q=\([^\&]*\).*/\1/';
    unset stream AGENT GOOG_URL Q
}

# }}} 

# {{{ nzb.queue()

function nzb.queue() {
    local target=/share/.usenet/queue/

    if [ ! -d ${target} ] ; then
        echo "Local target not available -> will use 'ssh enkheim.psaux.de'" >&2
        local action="scp -P2222"
        local target="simon@enkheim.psaux.de:${target}"
    else
        local action="mv -v"
    fi
    
    if [[ -z "${@}" ]] ; then
        if ls ~/Downloads/*[nN][zZ][bB] 2>/dev/null >&2 ; then
            if ( ${action} ~/Downloads/*[nN][zZ][bB] ${target} ) ; then
                rm -ri ~/Downloads/*[nN][zZ][bB]
            fi
        else
            echo "No nzb files found in the following dirs:" >&2
            echo " ~/Downloads/" >&2
            return 1
        fi
    else
        if ( ${action} ${@} ${target} ) ; then
            if [[ "$@" != "/" ]] && [[ "$@" != "." ]] && [[ "$@" != "" ]] ; then
                rm -ri ${@}
            fi
        fi
    fi
}

# }}} 

