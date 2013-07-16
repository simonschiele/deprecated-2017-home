[ -z "$PS1" ] && return

# {{{ Colors

if [ -x /usr/bin/tput ] && ( tput setaf 1 >&/dev/null ) ; then
    color_support=true
else
    color_support=false
fi

if ( $color_support ) && [[ "$TERM" =~ "xterm" ]]; then
    if [[ -n "$XTERM_VERSION" ]]; then
        # xterm
        COLORCOUNT="256"
    else
        if [[ $COLORTERM =~ "gnome-terminal" ]]; then
            # gnome-terminal
            COLORCOUNT="256"
        else
            # xterm compatible
            COLORCOUNT="256"
        fi
    fi
elif [[ "$TERM" =~ "linux" ]]; then
    # tty
    COLORCOUNT="8"
elif [[ "$TERM" =~ "rxvt" ]]; then
    # rxvt
    COLORCOUNT=`tput colors`
elif [[ "$TERM" =~ "screen*" ]]; then
    # screen or tmux
    COLORCOUNT="8"
else
    # unknown
    COLORCOUNT="8"
fi

export COLORCOUNT

RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
BLUE="\[\033[0;34m\]"
LIGHT_RED="\[\033[1;31m\]"
LIGHT_GREEN="\[\033[1;32m\]"
WHITE="\[\033[1;37m\]"
LIGHT_GRAY="\[\033[0;37m\]"
COLOR_BG_GRAY="\[\e[1;37;100m\]"
COLOR_BG_RED="\[\e[41;93m\]"
COLOR_NONE="\[\e[0m\]"

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;37m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

if [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
fi

if [ -e /usr/bin/colordiff ]
then
    alias diff='colordiff'
fi

# }}}

# {{{ Path

if [ -d ${HOME}/bin ]
then
    PATH="${HOME}/bin:$PATH"
fi

if [ -d ${HOME}/.bin ]
then
    PATH="${HOME}/.bin:$PATH"
fi

if [ -d ${HOME}/.bin-yps ]
then
    PATH="${HOME}/.bin-yps:$PATH"
fi

if [ -d ${HOME}/.hooks ]
then
    PATH="${HOME}/.hooks:$PATH"
fi

# }}}

# {{{ logout

if [ -x ${HOME}/.bash_logout ]
then
    trap "$HOME/.bash_logout" 0
elif [ -x ${HOME}/.logout ]
then
    trap "$HOME/.logout" 0
fi

# }}}

# {{{ Helper Functions

debian_packages_list() {
    type="${1}.list"
    if ! [ -e ${HOME}/.packages/${type} ] || [ -z "${@}" ]
    then
        echo "Unknown Systemtype '${HOME}/.packages/${type}'"
        return 1
    fi
    lists="$type $(grep ^[\.] ${HOME}/.packages/${type} | sed 's|^[\.]\ *||g')"
    lists=$( echo $lists | sed 's|\([A-Za-z0-9]*\.list\)|${HOME}/.packages/\1|g' )

    sed -e '/^\ *$/d' -e '/^\ *#/d' -e '/^[\.]/d' $( eval echo $lists ) | cut -d':' -f'2-' | xargs
}

convert2() {
    ext=${1} ; shift ; for file ; do echo -n ; [ -e "$file" ] && ( echo -e "\n\n[CONVERTING] ${file} ==> ${file%.*}.${ext}" && ffmpeg -loglevel error -i "${file}" -strict experimental "${file%.*}.${ext}" && echo rm -i "${file}" ) || echo "[ERROR] File not found: ${file}" ; done
}

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

confirm() {
    if [ "x${@}" == "x" ]
    then
        message="Are you sure you want to perform 'unknown action'?"
    else
        message="${@}"
    fi

    whiptail --yesno "${message}" 10 60
}

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

# {{{ vim

EDITOR=$( which vim.nox )
EDITOR=${EDITOR:-$( which vim )}
EDITOR=${EDITOR:-$( which nano )}
export EDITOR

alias vim.blank="${EDITOR} -N -u NONE -U NONE"

# check if powerline patched font for vim is available
if [ -n  "$( ls ~/.fonts/P*Pro/*owerline.ttf 2>/dev/null )" ]
then
    export POWERLINE_FONT="true"
else
    export POWERLINE_FONT="false"
fi

# }}}

# {{{ General Settings

# Vim navigation mode (use ESC)
# set -o vi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# bash_completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# git-flow-completion
if [ ~/.lib/git-flow-completion/git-flow-completion.bash ]
then
    source ~/.lib/git-flow-completion/git-flow-completion.bash
fi

# applications
export BROWSER=google-chrome
export TERMINAL="gnome-terminal.wrapper --disable-factory"

export PAGER=less
export HR="============================================================"

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTCONTROL=ignoreboth
shopt -s histappend

# }}}

# {{{ Aliases

# default overwrites
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias ll='ls -l'
alias mr='mr -d /'

# shorties
alias hr="for i in \$( seq 1 \$COLUMNS ) ; do echo -n '=' ; done ; echo"
alias t="true"
alias f="false"

# root
alias adduser_for_smb="sudo adduser --no-create-home --disabled-login --shell /bin/false"

# package and system-config
alias debian_version="lsb_release -a"
alias debian_packages_list_my="debian_packages_list \$(grep ^systemtype ~/.system.conf | cut -f'2-' -d'=' | sed 's|[\"]||g')"
alias debian_packages_list_by_size="dpkg-query -W --showformat='\${Installed-Size;10}\t\${Package}\n' | sort -k1,1n"
alias debian_packages_list_configfiles="dpkg-query -f '\n\n\${Package} \n\${Conffiles}' -W"
alias debian_packages_list_experimental='aptitude -t experimental search -F "%p %?V %?v %?t" --disable-columns .|grep -v none| grep experimental| awk "{if( \$2 == \$3) print \$1}"'
alias debian_packages_list_unstable="aptitude -t unstable search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep unstable| awk '{if( \$2 == \$3) print \$1}'"
alias debian_packages_list_testing="aptitude -t testing search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep testing| awk '{if( \$2 == \$3) print \$1}'"
alias debian_packages_list_stable="aptitude -t stable search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep stable| awk '{if( \$2 == \$3) print \$1}'"

# .hooks/
alias hooks_run="eval \$(grep ^systemtype ~/.system.conf 2>/dev/null) find ~/.hooks/ ! -type d -executable | xargs grep -l \"^hook_systemtype.*\${systemtype}\" | xargs grep -l '^hook_optional=false' | while read exe ; do \"\${exe}\" ; done"

# permission stuff
alias permissions_normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown ${SUDO_USER:-$USER}: . -R"
alias permissions_normalize_web="chown ${SUDO_USER:-$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:${SUDO_USER:-$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"
alias permissions_normalize_system="chown ${SUDO_USER:-$USER}: ~/ -R ; find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;"

# convert stuff
alias 2audio="convert2 mp3"
alias youtube-mp3="clive -f best --exec=\"echo >&2; echo '[CONVERTING] %f ==> MP3' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp3 && rm -i %f\""
alias youtube="clive -f best --exec=\"( echo %f | grep -qi -e 'webm$' -e 'webm.$' ) && ( echo >&2 ; echo '[CONVERTING] %f ==> MP4' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp4 && rm -f %f )\""
#alias image2pdf='convert -adjoin -page A4 *.jpeg multipage.pdf'				# convert images to a multi-page pdf
#nrg2iso() { dd bs=1k if="$1" of="$2" skip=300 }

# find
alias find_last_edited="find . -type f -printf \"%T@ %T+ %p\n\" | sort -n"
extensions_video="avi,mkv,mp4,mpg,mpeg,wmvlv,webm,3g"
alias find_videos="find . ! -type d $( echo ${extensions_video} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
extensions_images="png,jpg,jpeg,gif,bmp,tiff,ico"
alias find_images="find . ! -type d $( echo ${extensions_images} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"

# date
alias date.format="date --help | sed -n '/^FORMAT/,/%Z/p'"
alias date.timestamp='date +%s'
alias date.week='date +%V'
alias date.YY-mm-dd='date "+%Y-%m-%d"'
alias date.YY-mm-dd_HH_MM='date "+%Y-%m-%d_%H-%M"'

# magic
alias screenshot="import -display :0 -window root ./screenshot-\$(date +%Y-%m-%d_%s).png"
alias screendump="ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq ./screendump-\$(date +%Y-%m-%d_%s).mpg"
alias screenvideo="screendump"

alias grep_ip='grep -o '"'"'\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'"'"
alias grep_urls="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias grep_year="grep -o '[1-2]\{1\}[0-9]\{3\}'"
alias highlite="grep --color=auto -e ^ -e"
alias random_password="openssl rand -base64 12"
alias random_mac="openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'"
alias random_ip="nmap -iR 1 -sL -n | grep_ip -o"
alias random_lotto='shuf -i 1-49 -n 6 | sort -n | xargs'
alias scan_for_wlans="/sbin/iwlist scanning 2>/dev/null | grep -e 'Cell' -e 'Channel\:' -e 'Encryption' -e 'ESSID' -e 'WPA' | sed 's|Cell|\nCell|g'"
alias scan_for_hosts="fping -a -g \$(/sbin/ifconfig `/sbin/route -n | grep 'UG ' | head -n1 | awk {'print $8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').1 \$(/sbin/ifconfig `/sbin/route -n | grep 'UG '| head -n1 | awk {'print \$8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').254 2>/dev/null"
alias remove_last_line="sed '\$d'"
alias html_umlaute="sed -e 's|ü|\&uuml;|g' -e 's|Ü|\&Uuml;|g' -e 's|ä|\&auml;|g' -e 's|Ä|\&Auml;|g' -e 's|ö|\&ouml;|g' -e 's|Ö|\&Ouml;|g' -e 's|ß|\&szlig;|g'"
alias html_strip="sed -e 's|<[^>]*>||g'"
alias http_response="lwp-request -ds"
alias battery="upower -d | grep -e state -e percentage -e time | sed -e 's|^.*:\ *\(.*\)|\1|g' | sed 's|[ ]*$||g' | tr '\n' ' ' | sed -e 's|\ $|\n|g' | sed -e 's|^|(|g' -e 's|$|)|g'"
alias keycodes="sudo showkey -k"
alias stopwatch="time read"
alias silent='amixer -q sset "PCM" 0 ; amixer -q sset "MASTER" 0'
alias unsilent='amixer -q sset "PCM" 96 ; amixer -q sset "MASTER" 96'
alias mplayer_left="mplayer -xineramascreen 0"
alias mplayer_right="mplayer -xineramascreen 1"
alias patch_from_diff="patch -Np0 -i"
alias list_sticks="udisks --dump | grep device-file | sed 's|^.*\:\ *\(.*\)|\1|g' | while read dev ; do if ( udisks --show-info \${dev} | grep -q \"removable.*1\" ) ; then echo \${dev} ; fi ; done"
alias whatsmyip="wget -O- -q ip.nu | xargs | html_strip"
alias speedtest="wget -O- http://cachefly.cachefly.net/200mb.test >/dev/null"
alias route_via_wlan="for i in \`seq 1 10\` ; do route del default 2>/dev/null ; done ; route add default eth0 ; route add default wlan0 ; route add default gw \"\$( /sbin/ifconfig wlan0 | grep_ip | head -n 1 | cut -f'1-3' -d'.' ).1\""
alias pidgin_lastlog="find ~/.purple/logs/ -type f -mtime -1 | xargs tail -n 5"
alias sickbeard_skipped="sudo grep 'Found result' /var/log/sickbeard/sickbeard* | sed 's|\(.*\):\(.*[0-9]\:[0-9][0-9]\:[0-9][0-9]\).*\:\:\(.*\)\(at http.*\)|\2 - \3|g'"
alias mirror_complete="wget --random-wait -r -p -e robots=off -U mozilla"           # mirror website with everything
alias mirror_images='wget -r -l1 --no-parent -nH -nd -P/tmp -A".gif,.jpg" "$1"'	    # download all images from a site
alias show_colors="for i in \`seq 1 7 ; seq 30 48 ; seq 90 107\` ; do echo -e \"\e[\${i}mcolor \$i\e[0m\" ; done"
alias show_window_class='xprop | grep CLASS'
alias show_tcp='sudo netstat -atp'
alias show_tcp_stats='sudo netstat -st'
alias show_udp='sudo netstat -aup'
alias show_udp_stats='sudo netstat -su'
alias show_open_ports="echo 'User:      Command:   Port:'; echo '----------------------------' ; lsof -i 4 -P -n | grep -i 'listen' | awk '{print \$3, \$1, \$9}' | sed 's/ [a-z0-9\.\*]*:/ /' | sort -k 3 -n |xargs printf '%-10s %-10s %-10s\n' | uniq"	# lsof (cleaned up for just open listening ports)

# host/setup specific
if ( grep -q "minit" /proc/cmdline )
then
    alias reboot="sudo minit-shutdown -r &"
    alias halt="sudo minit-shutdown -h &"
fi

if ( grep -i -q work /etc/hostname )
then
    alias scp='scp -l 25000'
    alias windows='rdesktop -kde -a 16 -g 1280x1024 -u sschiele 192.168.80.55'
    alias start_windows='wakeonlan 00:1C:C0:8D:0C:73'
else
    alias start_mediacenter="wakeonlan 00:01:2e:27:62:87"
fi

# }}}

# {{{ Prompt

prompt_colored=true
prompt_git=true

if ( ! $color_support )
then
    prompt_colored=false
fi

function prompt_func () {
    lastret=$?

    if [[ -n "$SSH_CLIENT$SSH2_CLIENT$SSH_TTY" ]] ; then
        remote=true
    else
        remote=true
    fi

    if ( ${prompt_colored} )
    then
        PS1error=$( test $lastret -gt 0 && echo "${COLOR_BG_RED}[$lastret]${COLOR_NONE} ")
        PS1user="$( test $( id -u ) -eq 0 && echo ${RED})\u${COLOR_NONE}"
        PS1host="$( test -n "$SSH_CLIENT$SSH2_CLIENT$SSH_TTY" && echo ${RED})\h${COLOR_NONE}"
        PS1path="${COLOR_BG_GRAY}\w${COLOR_NONE}"
    else
        PS1error=$( test $lastret -gt 0 && echo "[$lastret] ")
        PS1user="\u"
        PS1host="\h"
        PS1path="\w"
    fi

    if ${prompt_git} && [[ -e "${HOME}/.lib/git_ps1.sh" ]] && [[ -n "$( which timeout )" ]]
    then
        PS1git=$( timeout 1 ${HOME}/.lib/git_ps1.sh ${prompt_colored} )
    else
        prompt_git=false
        PS1git=
    fi
    PS1git=${PS1git:+ ${PS1git}}
    PS1chroot=
    PS1prompt=" > "

    #PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    PS1="${PS1error}${PS1chroot}${PS1user}@${PS1host} ${PS1path}${PS1git}${PS1prompt}"
}

PROMPT_COMMAND=prompt_func

# use prompt from gitpromt project
#[[ $- == *i* ]]   &&   . ~/.lib/git-prompt/git-prompt.sh

# }}}

