
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

# {{{ Path, Includes, ...

for bin in bin .bin .bin-ypsilon .bin-private .hooks
do
    [ -d ${HOME}/${bin} ] && PATH="${HOME}/${bin}:${PATH}"
done

if [ -r ${HOME}/.lib/functions.sh ]
then
    source ${HOME}/.lib/functions.sh
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

# history
export HISTCONTROL=ignoreboth
export HISTFILESIZE=10000
export HISTSIZE=10000
export HISTIGNORE='&:clear:ls:cd:[bf]g:exit:[ t\]*'
export HOSTFILE=$HOME/.hosts
shopt -s histappend
#shopt -s histappend histreedit histverify
shopt -s cmdhist        # combine multiline
export PROMPT_COMMAND='history -a; history -n; $PROMPT_COMMAND'

# bash_completion
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# git-flow-completion
if [ ~/.lib/git-flow-completion/git-flow-completion.bash ]
then
    source ~/.lib/git-flow-completion/git-flow-completion.bash
fi

# applications
export BROWSER="google-chrome"
export MAILER="icedove"
export TERMINAL="gnome-terminal.wrapper --disable-factory"
export OPEN="gnome-open"

export PAGER=less
export HR="================================================================================"

# }}}

# {{{ Aliases

# default overwrites
alias cp='cp -i -r'
alias less='less'
alias mkdir='mkdir -p'
alias mr='mr -d /'
alias mv='mv -i'
alias rm='rm -i'
alias screen='screen -U'
alias wget='wget -c'
( which vim >/dev/null ) && alias vi='vim'

# sudo stuff
if [ $( id -u ) -eq 0 ]
then
    EDITOR='sudoedit'
    vi='sudoedit'
    vim='sudoedit'
fi
alias sudo='sudo '
alias sudothat='eval "sudo $(fc -ln -1)"'

# sudo stuff
if [ $( id -u ) -eq 0 ]
then
    vi='sudoedit'
    vim='sudoedit'
fi
alias sudo='sudo '
alias sudothat='eval "sudo $(fc -ln -1)"'

# shorties
alias hr="for i in \$( seq \${COLUMNS:-80} ) ; do echo -n '=' ; done ; echo"
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
alias hooks_run="echo ; systemtype=\$( grep ^systemtype ~/.system.conf | cut -f2 -d'=' | sed -e 's|[\"\ ]||g' -e \"s|'||g\" ) ; for exe in \$( find ~/.hooks/ ! -type d -executable | xargs grep -l \"^hook_systemtype.*\${systemtype}\" | xargs grep -l '^hook_optional=false' ) ; do exec_with_sudo='' ; grep -q 'hook_sudo=.*true.*' \"\${exe}\" && exec_with_sudo='sudo ' || grep -q 'hook_sudo' \"\${exe}\" || exec_with_sudo='sudo ' ; cancel=\${cancel:-false} global_success=\${global_success:-true} \${exe} ; retval=\${?} ; echo ; if test \${retval} -eq 2 ; then echo -e \"CANCELING HOOKS\" >&2 ; break ; elif ! test \${retval} -eq 0 ; then global_success=false ; fi ; done ; \${global_success} || echo -e \"Some hooks could NOT get processed successfully!\n\" ; unset global_success systemtype retval ;"

# permission stuff
alias permissions_normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown ${SUDO_USER:-$USER}: . -R"
alias permissions_normalize_web="chown ${SUDO_USER:-$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:${SUDO_USER:-$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"
alias permissions_normalize_system="chown ${SUDO_USER:-$USER}: ~/ -R ; find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;"

# find
extensions_video="avi,mkv,mp4,mpg,mpeg,wmv,wmvlv,webm,3g,mov"
extensions_images="png,jpg,jpeg,gif,bmp,tiff,ico,lzw,raw,ppm,pgm,pbm,psd,img,xcf,psp,svg,ai"
extensions_audio="flac,mp1,mp2,mp3,ogg,wav,aac,ac3,dts,m4a,mid,midi,mka,mod,oma,wma"
extensions_documents="doc,xls,abw,chm,pdf,docx,docm,odm,odt,rtf,stw,sxg,sxw,wpd,wps,ods,pxl,sxc,xlsx,xlsm,odg,odp,pps,ppsx,ppt,pptm,pptx,sda,sdd,sxd,dot,dotm,dotx"
extensions_archives="7z,ace,arj,bz,bz2,gz,lha,lzh,rar,tar,taz,tbz,tbz2,tgz,zip"
crap=".DS_Store"
alias find.videos="find . ! -type d $( echo ${extensions_video} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
alias find.images="find . ! -type d $( echo ${extensions_images} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
alias find.audio="find . ! -type d $( echo ${extensions_audio} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
alias find.documents="find . ! -type d $( echo ${extensions_documents} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
alias find.archives="find . ! -type d $( echo ${extensions_archives} | sed -e 's|,|\ \-o\ \-iname *|g' -e 's|^|\ \-iname *|g' )"
alias find.dir="find . -type d"
alias find.file="find . ! -type d"
alias find.string=""
alias find.exec=""
alias find.last_edited='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 300'
alias find.last_accessed=""

# date/time stuff
alias date.format="date --help | sed -n '/^FORMAT/,/%Z/p'"
alias date.timestamp='date +%s'
alias date.week='date +%V'
alias date.YY-mm-dd='date "+%Y-%m-%d"'
alias date.YY-mm-dd_HH_MM='date "+%Y-%m-%d_%H-%M"'
alias date.world=worldclock
alias date.stopwatch=stopwatch
alias stopwatch="time read -n 1"

# compression
alias zip.dir="compress zip"
alias rar.dir="compress rar"
alias tar.dir="compress targz"

# mirror
alias mirror.complete="wget --random-wait -r -p -e robots=off -U mozilla"           # mirror website with everything
alias mirror.images='wget -r -l1 --no-parent -nH -nd -P/tmp -A".gif,.jpg" "$1"'	    # download all images from a site

# filter
alias grep.ip='grep -o '"'"'\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'"'"
alias grep.urls="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias grep.year="grep -o '[1-2]\{1\}[0-9]\{3\}'"

# randoms
alias random.mac="openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'"
alias random.ip="nmap -iR 1 -sL -n | grep.ip -o"
alias random.lotto='shuf -i 1-49 -n 6 | sort -n | xargs'
random.password() { openssl rand -base64 ${1:-8} ; }
random.hex() { openssl rand -hex ${1:-8} ; }

# magic
alias screenshot="import -display :0 -window root ./screenshot-\$(date +%Y-%m-%d_%s).png"
alias screendump="ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq ./screendump-\$(date +%Y-%m-%d_%s).mpg"
alias screenvideo="screendump"

alias calculator="bc -l"
alias highlite="grep --color=auto -e ^ -e"
alias scan_for_wlans="/sbin/iwlist scanning 2>/dev/null | grep -e 'Cell' -e 'Channel\:' -e 'Encryption' -e 'ESSID' -e 'WPA' | sed 's|Cell|\nCell|g'"
alias scan_for_hosts="fping -a -g \$(/sbin/ifconfig `/sbin/route -n | grep 'UG ' | head -n1 | awk {'print $8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').1 \$(/sbin/ifconfig `/sbin/route -n | grep 'UG '| head -n1 | awk {'print \$8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').254 2>/dev/null"
alias remove_last_line="sed '\$d'"
alias html_umlaute="sed -e 's|ü|\&uuml;|g' -e 's|Ü|\&Uuml;|g' -e 's|ä|\&auml;|g' -e 's|Ä|\&Auml;|g' -e 's|ö|\&ouml;|g' -e 's|Ö|\&Ouml;|g' -e 's|ß|\&szlig;|g'"
alias html_strip="sed -e 's|<[^>]*>||g'"
alias http_response="lwp-request -ds"
alias battery="upower -d | grep -e state -e percentage -e time | sed -e 's|^.*:\ *\(.*\)|\1|g' | sed 's|[ ]*$||g' | tr '\n' ' ' | sed -e 's|\ $|\n|g' | sed -e 's|^|(|g' -e 's|$|)|g'"
alias keycodes="xev | grep 'keycode\|button'"
alias silent='amixer -q sset "PCM" 0 ; amixer -q sset "MASTER" 0'
alias unsilent='amixer -q sset "PCM" 96 ; amixer -q sset "MASTER" 96'
alias mplayer_left="mplayer -xineramascreen 0"
alias mplayer_right="mplayer -xineramascreen 1"
alias patch_from_diff="patch -Np0 -i"
alias list_sticks="udisks --dump | grep device-file | sed 's|^.*\:\ *\(.*\)|\1|g' | while read dev ; do if ( udisks --show-info \${dev} | grep -q \"removable.*1\" ) ; then echo \${dev} ; fi ; done"
alias whatsmyip="wget -O- -q ip.nu | xargs | html_strip"
alias whatsmyresolution="LANG=C xrandr -q | grep -o \"current [0-9]\{3,4\} x [0-9]\{3,4\}\" | sed -e 's|current ||g' -e 's|\ ||g'"
alias speedtest="wget -O- http://cachefly.cachefly.net/200mb.test >/dev/null"
alias route_via_wlan="for i in \`seq 1 10\` ; do route del default 2>/dev/null ; done ; route add default eth0 ; route add default wlan0 ; route add default gw \"\$( /sbin/ifconfig wlan0 | grep.ip | head -n 1 | cut -f'1-3' -d'.' ).1\""
alias pidgin_lastlog="find ~/.purple/logs/ -type f -mtime -1 | xargs tail -n 5"
alias sickbeard_skipped="sudo grep 'Found result' /var/log/sickbeard/sickbeard* | sed 's|\(.*\):\(.*[0-9]\:[0-9][0-9]\:[0-9][0-9]\).*\:\:\(.*\)\(at http.*\)|\2 - \3|g'"
alias show_colors="for i in \`seq 1 7 ; seq 30 48 ; seq 90 107\` ; do echo -e \"\e[\${i}mcolor \$i\e[0m\" ; done"
alias show_window_class='xprop | grep CLASS'
alias show_tcp='sudo netstat -atp'
alias show_tcp_stats='sudo netstat -st'
alias show_udp='sudo netstat -aup'
alias show_udp_stats='sudo netstat -su'
alias show_open_ports="echo 'User:      Command:   Port:'; echo '----------------------------' ; lsof -i 4 -P -n | grep -i 'listen' | awk '{print \$3, \$1, \$9}' | sed 's/ [a-z0-9\.\*]*:/ /' | sort -k 3 -n |xargs printf '%-10s %-10s %-10s\n' | uniq"	# lsof (cleaned up for just open listening ports)
alias ssh.untrusted='ssh -o "StrictHostKeyChecking no"'
#alias btc="echo \"[\$( wget -O- -q https://bitpay.com/api/rates | grep -P -o '{.*?EUR".*?}' )]\" | json_pp -f json -json_opt pretty"

# convert stuff
alias 2audio="convert2 mp3"
alias youtube-mp3="clive -f best --exec=\"echo >&2; echo '[CONVERTING] %f ==> MP3' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp3 && rm -f %f\""
alias youtube="clive -f best --exec=\"( echo %f | grep -qi -e 'webm$' -e 'webm.$' ) && ( echo >&2 ; echo '[CONVERTING] %f ==> MP4' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp4 && rm -f %f )\""
#alias image2pdf='convert -adjoin -page A4 *.jpeg multipage.pdf'				# convert images to a multi-page pdf
#nrg2iso() { dd bs=1k if="$1" of="$2" skip=300 }

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

