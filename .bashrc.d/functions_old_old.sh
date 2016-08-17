#!/bin/bash

# {{{ whereami()

function whereami() {

    local ips=$( /sbin/ifconfig | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -u | grep -v -e "^127" -e "^255" )
    if ( grep -q -i wlan-ap[0-9] <( /sbin/iwconfig 2>&1 )) && ( grep -q -i 192\.168\.190 <( /sbin/ifconfig 2>&1 )) ; then
        echo "work-mobile"
    elif ( echo $ips | grep -q -e "192\.168\.[78]0" -e "195\.4\.7[01]" ) ; then
        echo "work"
    elif ( echo $ips | grep -q -e "192\.168\.5" ) ; then
        echo "home"
    else
        echo "unknown"
    fi
}

# }}}

# {{{ nzb.queue()

function nzb.queue() {
    local target=/share/.queue/
    local delete=true

    if [ ! -d ${target} ] ; then
        echo "Local target not available -> will use 'ssh enkheim.psaux.de'" >&2
        local action="scp -P2222"
        local target="simon@enkheim.psaux.de:${target}"
    else
        local action="mv -v"
        local delete=false
    fi

    if [[ -z "${@}" ]] ; then
        if ls ~/Downloads/*[nN][zZ][bB] 2>/dev/null >&2 ; then
            if ( ${action} ~/Downloads/*[nN][zZ][bB] ${target} ) ; then
                ( ${delete} ) && rm -ri ~/Downloads/*[nN][zZ][bB]
            fi
        else
            echo "No nzb files found in the following dirs:" >&2
            echo " ~/Downloads/" >&2
            return 1
        fi
    else
        if ( ${action} ${@} ${target} ) ; then
            if [[ "$@" != "/" ]] && [[ "$@" != "." ]] && [[ "$@" != "" ]] ; then
                ( ${delete} ) && rm -ri ${@}
            fi
        fi
    fi
}

# }}}

# {{{ web.*

function web.google() {
    local Q="$@";
    local GOOGLE_URL='https://www.google.com/search?tbs=li:1&q=';
    local AGENT="Mozilla/4.0";
    local stream=$(curl -A "$AGENT" -skLm 10 "${GOOGLE_URL}${Q//\ /+}");
    echo "$stream" | grep -o "href=\"/url[^\&]*&amp;" \
                   | sed 's/href=".url.q=\([^\&]*\).*/\1/';
}

alias web.btc_worldwide='wget -q -O- https://bitpay.com/api/rates | json_pp'
alias web.btc='echo -e "€: $( web.btc_worldwide | grep -C2 Euro | grep -o [0-9\.]* )" ; echo "$: $( btc.worldwide | grep -C2 USD | grep -o [0-9\.]* )"'
alias btc=web.btc
alias btc_worldwide=web.btc_worldwide

# }}}

# {{{ date.* + date/time stuff

worldclock() {
    local zones tz tz_short

    zones="America/Los_Angeles America/Vancouver America/Denver America/Chicago"
    zones+=" America/Detroit Cuba America/New_York America/Toronto Iceland"
    zones+=" Europe/London Europe/Paris Europe/Berlin Europe/Moscow"
    zones+=" Asia/Hong_Kong Australia/Sydney NZ"

    for tz in $zones
    do
        tz_short=$( basename $tz )
        echo -n -e "${tz_short}\t"
        [[ ${#tz_short} -lt 8 ]] && echo -n -e "\t"
        TZ=${tz} date
    done
}

alias date.format='date --help | sed -n "/^FORMAT/,/%Z/p"'
alias date.timestamp='date +%s'
alias date.week='date +%V'
alias date.YY-mm-dd='date "+%Y-%m-%d"'
alias date.YY-mm-dd_HH_MM='date "+%Y-%m-%d_%H-%M"'
alias date.worldclock=worldclock
alias date.stopwatch=stopwatch
alias stopwatch='time read -n 1'

# }}}

# {{{ debian.*

function debian.add_pubkey() {
    if ! ( ${ESSENTIALS_IS_UID0} ) ; then
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
        if ( sudo gpg --keyserver pgpkeys.mit.edu --recv-key ${1} ) && ( sudo gpg -a --export ${1} | sudo apt-key add - ) ; then
            return 0
        else
            return 1
        fi
    fi
}

function debian.security() {
    wget -q -O- https://www.debian.org/security/dsa \
        | xml2 \
        | grep -o -e "item/title=.*$" -e "item/dc:date=.*$" -e "item/link=.*$" \
        | tac \
        | cut -f'2-' -d'=' \
        | sed -e ':a;N;$!ba;s/\n/ /g' -e 's/\(20[0-9]\{2\}-\)/\n\1/g' \
        | awk {'print $1" "$4" ("$2")"'} \
        | sed "s|^|\ \ $( echo -e ${ICONS[fail]})\ \ |g" \
        | tac \
        | head -n ${1:-6}
}

function debian.packages_custom_get() {
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

alias debian.version='lsb_release -a'
alias debian.bugs='bts'
alias debian.packages_custom='debian.packages_custom_get $(grep ^system_type ~/.system.conf | cut -f"2-" -d"=" | sed "s|[\"]||g")'
alias debian.packages_by_size='dpkg-query -W --showformat="\${Installed-Size;10}\t\${Package}\n" | sort -k1,1n'
alias debian.package_configfiles='dpkg-query -f "\n${Package} \n${Conffiles}\n" -W'

# }}}

# {{{ scan.*

alias scan.wlans='/sbin/iwlist scanning 2>/dev/null | grep -e "Cell" -e "Channel:" -e "Encryption" -e "ESSID" -e "WPA" | sed "s|Cell|\nCell|g"'

function scan.hosts() {
    local routing_interface=$( LANG=C /sbin/route -n | grep "^[0-9 :\.]\+ U .*[a-z]\+[0-9]\+" | head -n 1 )
    local routing_interface=${routing_interface##* }
    local network="$( LANG=C /sbin/ifconfig ${routing_interface} | grep -o 'inet addr[^ ]*' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.' )0/24"
    fping -q -a -g ${network} | while read ip ; do
        echo -ne "${ip}\t"
        echo -e "$( host -W 1 ${ip} | grep -o '[^ ]*.$' | sed 's|\.$||g' )"
    done
}

# }}}

# {{{ save.* (battery stuff)

alias battery.show='upower -d | grep -e state -e percentage -e time | sort -u | tr "\n" " " | sed "s|^[^0-9]*\([0-9]*%\)[^:]*:\ *\([^\ ]*\)[^0-9\.]*\([0-9\.]*\)[^0-9]*$|(\1, \2, \3h)|g"; echo'

function battery.save_lifetime() {
    echo 15 > /sys/devices/platform/smapi/BAT0/start_charge_thresh
    echo 85 > /sys/devices/platform/smapi/BAT0/stop_charge_thresh
}

function battery.save() {
    if ! [ $( id -u ) -eq 0 ] ; then
        echo "please use root or sudo -s" >&2
        return 1
    fi
    local f

    es_debug " * setting gov powersave for all $( grep ^process /proc/cpuinfo | wc -l ) cores"
    ${ESSENTIALS_DEBUG} && echo -n "[LOG]   " >&2
    seq 0 $( grep ^process /proc/cpuinfo | tail -n 1 | grep -o "[0-9]" ) | while read i ; do
        ${ESSENTIALS_DEBUG} && echo -n " ${i}" >&2
        cpufreq-set -c ${i} -g powersave
    done
    ${ESSENTIALS_DEBUG} && echo "" >&2

    es_debug " * turn off NMI watchdog"
    echo '0' > '/proc/sys/kernel/nmi_watchdog'

    es_debug " * auto suspend bluetooth"
    echo 'auto' > /sys/bus/usb/devices/1-1.4/power/control

    es_debug " * auto suspend umts modem"
    echo 'auto' > /sys/bus/usb/devices/2-1.4/power/control

    es_debug " * deactivate WOL for eth0"
    ethtool -s enp0s25 wol d

    es_debug " * enable audio codec power management"
    echo '1' > /sys/module/snd_hda_intel/parameters/power_save

    es_debug " * setting VM writeback timeout to 1500"
    echo '1500' > /proc/sys/vm/dirty_writeback_centisecs

    es_debug " * wireless power saving for wlan0"
    iw dev wlp2s0 set power_save on

    es_debug " * activating sata link power managenment on host0-host$(( $( ls /sys/class/scsi_host/host*/link_power_management_policy | wc -l ) - 1 ))"
    seq 0 $(( $( ls /sys/class/scsi_host/host*/link_power_management_policy | wc -l ) - 1 )) | while read i ; do
        echo 'min_power' > /sys/class/scsi_host/host${i}/link_power_management_policy
    done

    es_debug " * enabling power control for pci bus"
    for f in /sys/bus/pci/devices/*/power/control ; do echo 'auto' > "$f" ; done

    es_debug " * enabling power control for usb bus"
    for f in /sys/bus/usb/devices/*/power/control ; do echo 'on' > "$f" ; done
    for f in /sys/bus/usb/devices/*/power/control ; do echo 'auto' > "$f" ; done
}

alias show.battery=battery.show
alias save.battery=battery.save
alias save.battery_lifetime=battery.save_lifetime

# }}}

# {{{ no.*

function no.sleep() {
    local status=0

    # kill screensaver
    pkill -f screensaver >/dev/null 2>&1
    ( pgrep screensaver ) && echo "warning: couldn't kill screensaver" >&2 && status=1

    # disable dpms
    xset -display ${DISPLAY:-:0} -dpms
}

alias no.blank=no.sleep
alias no.screensaver=no.sleep
alias no.sound=alsa.silent
alias no.audio=alsa.silent

# }}}

# {{{ show.*

function show.tlds() {
    [ ! -d ${HOME}/.cache/bash/ ] && mkdir -p ${HOME}/.cache/bash/
    if [ ! -e ${HOME}/.cache/bash/tlds ] ; then
        wget -q "http://data.iana.org/TLD/tlds-alpha-by-domain.txt" -O ${HOME}/.cache/bash/tlds
    fi
    grep -v -e "^\ *$" -e "^\ *#" ${HOME}/.cache/bash/tlds
}

function grep.tld() {
    function process() {
        local iinput
        echo "${1}" | grep -o "[^\ \"\']\+\.[A-Za-z]\+" | while read iinput ; do
            local clean_input=${iinput##*.}
            show.tlds | grep "^${clean_input}$"
        done
    }

    local input

    while read -t 1 -r input ; do
        [ -z "${input}" ] && break
        process "${input}"
    done

    for input in ${@} ; do
        process "${input}"
    done

    unset process
}

function show.path() {
    local path="${1}"
    local path_real=$( readlink -f "${path}" )
    local filetype=$( file -b "${path}" )
    local filetype_real=$( file -b "${path_real}" )
    local size=$( ls -s "${path_real}" | awk {'print $1'} )
    local size_human=$( ls -sh "${path_real}" | awk {'print $1'} )

    echo -e "name:\t\t$( color white_bold )${path}$( color none )"
    echo -e "type:\t\t${filetype}"

    if [ -h "${path}" ] ; then
        echo -e "real path:\t${path_real}"
        echo -e "real type:\t${filetype_real}"
    fi

    if [ -d "${real_path}" ] ; then
        echo
    else
        echo -e "size:\t\t${size_human} (${size})"
        echo
    fi
}

alias show.dir=show.path
alias show.file=show.path

function show.host() {
    local ip=$( echo "${1}" | grep.ip | head -n 1 )
    local host=${1}

    if [ -n "$host" ] && [ -z "$ip" ] ; then
        ip=$( host ${host} | grep "has address " | grep.ip )
    elif [ -n "$ip" ] ; then
        host=$( host ${ip} | grep "domain name pointer" | sed 's|.*pointer\ \(.*\)\.$|\1|g' )
    else
        echo "'${1}' neither ip address nor hostname"
        return 1
    fi

    echo "host: ${host}"
    echo "ip: ${ip}"
}

function show() {
    if [ -z "${1}" ] ; then
        echo "usage: show <file|dir|url|ip|int|string>"
    elif [ -e "${1}" ] ; then
        show.path "${1}"
    elif echo "${1}" | grep.ip ; then
        show.host "${1}"
    elif ( echo "${1:$((${#1}-8))}" | grep -q "\." ) && ( show.tlds | grep $( echo "${1:$((${#1}-8))}" | cut -f"2-" -d"." ) ) ; then
        show.host "${1}"
    else
        echo "input not identified"
    fi
}

function show.stats() {
    color.echon "white_bold" "Date: " ; date +'%d.%m.%Y (%A, %H:%M)'
    color.echon "white_bold" "Host: " ; hostname
    color.echon "white_bold" "Location: " ; whereami
    color.echon "white_bold" "Systemtype: " ; echo "${system_type}"

    echo -e "\n$( color white_under )$( color white_bold )Hardware:$( color )"

    local cpu=$( grep "^model\ name" /proc/cpuinfo | sed -e "s|^[^:]*:\([^:]*\)$|\1|g" -e "s/[\ ]\{2\}//g" -e "s|^\ ||g" )
    echo -e 'cpu: '$( echo -e "$cpu" | wc -l )'x '$( echo "$cpu" | head -n1 )

    local ram=$( LANG=c free -m | grep ^Mem | awk {'print $2'} )
    echo -ne "ram: ${ram}mb (free: $( free -m | grep cache\: | awk {'print $4'} )mb, "
    #free | awk '/Mem/{printf("used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%"), $4/($3+$4)*100} /Swap/{printf(", swap: %.2f%"), $3/$2*100}'

    local swap=$( LANG=c free | grep "^swap" | sed 's|^swap\:[0\ ]*||g' )
    [ -z "$swap" ] && echo -n "swap: no active swap" || echo -n "swap: ${swap}"
    echo ")"

    LANG=C df -h | grep "\ /$" | awk {'print "hd: "$2" (root, free: "$4")"'}
}

alias show.ip_remote='addr=$( dig +short myip.opendns.com @resolver1.opendns.com | grep.ip ) ; echo remote:${addr:-$( wget -q -O- icanhazip.com | grep.ip )}'
alias show.ip_local='LANG=C /sbin/ifconfig | grep -o -e "^[^\ ]*" -e "^\ *inet addr:\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | tr "\n" " " | sed -e "s|\ *inet addr||g" -e "s|\ |\n|g"' #-e "s|:\(.*\)$|: $( color yellow )\1$( color none )|g"'
alias show.ip='show.ip_local | sed "s|:\(.*\)$|: $( color yellow )\1$( color none )|g" ; show.ip_remote | sed "s|:\(.*\)$|: $( color green )\1$( color none )|g"'

# generate show.<interface> aliases
for tmpname in $( /sbin/ifconfig | grep -o "^[^ ]*" ) ; do
    alias show.${tmpname}="$( echo /sbin/ifconfig ${tmpname} )"
done
unset tmpname

alias show.io='echo -n d | nmon -s 1'
alias show.tcp='sudo netstat -atp'
alias show.tcp_stats='sudo netstat -st'
alias show.udp='sudo netstat -aup'
alias show.udp_stats='sudo netstat -su'
alias show.window_class='xprop | grep CLASS'
alias show.resolution='LANG=C xrandr -q | grep -o "current [0-9]\{3,4\} x [0-9]\{3,4\}" | sed -e "s|current ||g" -e "s|\ ||g"'
alias show.certs='openssl s_client -connect '
alias show.keycodes='xev | grep -e keycode -e button'
alias show.usb_sticks='for dev in $( udisks --dump | grep device-file | sed "s|^.*\:\ *\(.*\)|\1|g" ) ; do udisks --show-info ${dev} | grep -qi "removable.*1" && echo ${dev} ; done ; true ; unset dev'

# }}}

# {{{ is.*

function is.systemd() {
    sudo LANG=C lsof -a -p 1 -d txt | grep -q "^systems\ *1\ *"
    return $?
}

function is.init_five() {
    find /etc/rc[1-5].d/ ! -type d -executable -exec basename {} \; | sed 's/^[SK][0-9][0-9]//g' | sort -u | xargs
}

# }}}

# {{{ find.*

alias find.dir='find -type d'
alias find.files='find -type f'
alias find.exec='find ! -type d -executable'
alias find.repos='find -name .git -or -name .svn -or -name .bzr -or -name .hg -or -name CSV | while read dir ; do echo "$dir" | sed "s|\(.\+\)/\.\([a-z]\+\)$|\2: \1|g" ; done'
alias find.comma='ls -r --format=commas'
alias find.dead.links='find.dead_links'
alias find.links='find -type l'
alias find.links.dead='find -L -type l'
alias find.bigger.10m='find -size +10M'
alias find.bigger.100m='find -size +100M'
alias find.bigger.1000m='find -size +1000M'
alias find.last_edited='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 1000'
alias find.last_edited.1000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 1000'
alias find.last_edited.3000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 3000'
alias find.last_edited.5000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 5000'
alias find.last_edited.10000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 10000'
alias find.last_edited.30000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 30000'
alias find.last_edited.50000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 50000'
alias find.last_edited.100000='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 100000'
alias find.last_edited.less='find . -type f -printf "%T@ %T+ %p\n" | sort -n | less'

function find.tree() {
    local dir="${1}"

    if [ "${dir}" == "-d" ] ; then
        shift
        local dir_find="-type d "
        dir="${1}"
    fi

    #| sed -e 's;[^/]*/;|__;g;s;__|; |;g'
    echo find "${dir:-.}" ${dir_find} -print
}

alias find.videos="find . ! -type d $( echo ${EXTENSIONS_VIDEO}\" | sed -e "s|,|\"\ \-o\ \-iname \"*|g" -e "s|^|\ \-iname \"*|g" )"
alias find.images="find . ! -type d $( echo ${EXTENSIONS_IMAGES}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.audio="find . ! -type d $( echo ${EXTENSIONS_AUDIO}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.documents="find . ! -type d $( echo ${EXTENSIONS_DOCUMENTS}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.archives="find . ! -type d $( echo ${EXTENSIONS_ARCHIVES}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"

# }}}

# {{{ git.*

function git.subupd() {
    git submodule foreach git fetch origin --tags && git pull && git submodule update --init --recursive
}

function git.is_submodule() {
     (cd "$(git rev-parse --show-toplevel)/.." && git rev-parse --is-inside-work-tree) | grep -q true
}

# }}}

# {{{ sudo.*

alias sudo.that='eval "sudo $(fc -ln -1)"'
alias sudo.password_disable='sudo grep -iq "^${SUDO_USER:-${USER}}.*NOPASSWD.*ALL.*$" /etc/sudoers && echo "entry already in /etc/sudoers" >&2 || sudo bash -c "echo -e \"${SUDO_USER:-${USER}}\tALL = NOPASSWD:  ALL\n\" >> /etc/sudoers"'
alias sudo.password_enable='sudo grep -iq "^${SUDO_USER:-${USER}}.*NOPASSWD.*ALL.*$" /etc/sudoers && sudo sed -i "/^${SUDO_USER:-${USER}}.*NOPASSWD.*ALL.*$/d" /etc/sudoers || echo "entry not in /etc/sudoers" >&2'

# }}}

# {{{ log.*

alias log.dmesg='dmesg -T --color=auto'
alias log.pidgin='find ~/.purple/logs/ -type f -mtime -5 | xargs tail -n 5'
alias log.networkManager='sudo journalctl -u NetworkManager'
alias log.authlog="sudo grep -e \"^\$( LANG=C date -d'now -24 hours' +'%b %e' )\" -e \"^\$( LANG=C date +'%b %e' )\" /var/log/auth.log | grep.ip | sort -n | uniq -c | sort -n | grep -v \"\$( host -4 enkheim.psaux.de | grep.ip | head -n1 )\" | tac | head -n 10"

# }}}

# {{{ grep.*

alias grep.ip='grep -o "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}"'
alias grep.url="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias grep.year='grep -o "[1-2][0-9]\{3\}"'
alias grep.where="grep -nH"
alias grep.highlite+passthru='grep --color=yes -e ^ -e'

# }}}

# {{{ random.*

alias random.ip='nmap -iR 1 -sL -n | grep.ip -o'
alias random.mac='openssl rand -hex 6 | sed "s/\(..\)/\1:/g; s/.$//"'
alias random.lotto='shuf -i 1-49 -n 6 | sort -n | xargs'

function random.password() {
    local password password_first_char password_last_char

    while [ -z "$password" ] ; do #|| [ "${pass:0:1}" ] ; do
        password=$( openssl rand -base64 $(( ${1:-8} * 2 )) | cut -c1-${1:-8} )
        password_first_char=${password:0:1}
        password_last_char=${password: -1}
        echo "pass: $password"
        echo "pass_f: $password_first_char"
        echo "pass_l: $password_last_char"
    done

    echo "$password"
    return 0
}

function random.hex() {
    local hex=$( openssl rand -hex ${1:-8} )
}

function random.integer() {
    local from=1;
    local to=${1:-100};

    [[ -n "${2}" ]] && from=${1} && to=${2}
    [ "$from" == "0" ] && to=$(( $to + 1 ))

    echo "$(( RANDOM % ${to:-100} + ${from:-1} ))"
}

# }}}

# {{{ sed.*

alias sed.remove_special_chars='sed "s,\x1B\[[0-9;]*[a-zA-Z],,g"'
alias sed.strip_html='sed -e "s|<[^>]*>||g"'
alias sed.htmlencode_umlaute='sed -e "s|ü|\&uuml;|g" -e "s|Ü|\&Uuml;|g" -e "s|ä|\&auml;|g" -e "s|Ä|\&Auml;|g" -e "s|ö|\&ouml;|g" -e "s|Ö|\&Ouml;|g" -e "s|ß|\&szlig;|g"' # todo: untested
alias sed.strip_doubleslash='sed "s|[/]\+|/|g"'

# }}}

# {{{ alsa.*

function alsa.volume() {
    local percentage=$( echo ${1} | sed 's|[^0-9]||g' )
    percentage=${percentage:-75}

    local mix
    local mixer="PCM MASTER Master"
    for mix in $mixer ; do
        amixer -q sset $mix ${percentage}% 2>/dev/null
    done
}

alias alsa.loud='alsa.volume 100'
alias alsa.medium='alsa.volume 75'
alias alsa.silent='alsa.volume 0'
alias alsa.mute=alsa.silent

# }}}

# {{{ permissions.*

alias permissions.normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown \${SUDO_USER:-\$USER}: . -R"
alias permissions.normalize_system="chown \${SUDO_USER:-\$USER}: ~/ -R ; find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;"
alias permissions.normalize_web="chown \${SUDO_USER:-\$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:\${SUDO_USER:-\$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"

# }}}

# {{{ kvm.*, qcow.*, iso.*

alias iso.grml='iso=$( ls -rt /share/Software/images/grml96*iso 2>/dev/null | tail -n1 ) ; iso=${iso:-$( find /boot -iname "grml*iso" 2>/dev/null )} ; iso=${iso:-$( find ~/ -iname "*grml*iso" 2>/dev/null | tail -n1 )} ; echo "$iso" ; unset iso'
alias kvm.hd='kvm -m 1024 -boot c -hda'
alias kvm.grml+hd='iso=$( iso.grml ) ; kvm -cdrom ${iso} -m 1024 -boot d -hda ; unset iso'
alias create.qcow='next=$( printf "%02d\n" "$(( $( ls image_[0-9]*.img 2>/dev/null | grep -o [0-9]* | sort -n | tail -n1 ) + 1 ))" ) ; qemu-img create -f qcow2 -o preallocation=metadata image_${next}.img ; unset next'

# }}}

# {{{ convert.*

function convert.img2pdf() {
    local in="${@:-*.jpeg}"
    local out="out_multipage.pdf"
    convert -adjoin -page A4 ${in} ${out}
}

function convert.nrg2iso() {
    local nrg iso msg
    nrg=${1:-$( ( shopt -s nocaseglob ; ls -t *.nrg 2>/dev/null | head -n 1 ) )}
    iso=${2:-${nrg/nrg/iso}}

    if [ -z "${nrg}" ] ; then
        msg="usage error - please call like this:\n > convert.nrg2iso infile.nrg [outfile.iso]"
    elif [ ! -e "${nrg}" ] ; then
        msg="error: couldn't find file '${nrg}'"
    elif [ ! -r "${nrg}" ] ; then
        msg="error: couldn't read exisiting file '${nrg}'"
    else
        ${ESSENTIALS_DEBUG} && echo "${nrg} -> ${iso}"
        time dd bs=1k if="${nrg}" of="${iso}" skip=300
        return 0
    fi

    echo -e "${msg}" >&2
    return 1
}

# }}}

# {{{ screenshot

if ( which recordmydesktop >/dev/null ) ; then
    alias screenrecord='recordmydesktop -o screendump_$( date +%s ).ogv'
elif ( which ffmpeg >/dev/null ) ; then
    alias screenrecord='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq ./screendump-$(date +%Y-%m-%d_%s).mpg'
    alias screenrecord2='ffmpeg -f alsa -i hw:1,1 -f x11grab -r 30 -s 800x600 -i :0.0 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -threads 0 output.avi'
fi

if ( which gnome-screenshot >/dev/null ) ; then
    alias screenshot=gnome-screenshot
else
    alias screenshot='import -display :0 -window root ./screenshot-$(date +%Y-%m-%d_%s).png'
fi

# }}}

