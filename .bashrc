[ -z "$PS1" ] && return

# {{{ Colors

if [[ "$TERM" =~ "xterm" ]]; then
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

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

export PAGER=less
export EDITOR="/usr/bin/vim"

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTCONTROL=ignoreboth
shopt -s histappend

alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias ll='ls -l'
alias mr='mr -d /'

alias debian_version="lsb_release -a"
alias grep_ip='grep -o '"'"'\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'"'"
alias grep_urls="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias random_password="openssl rand -base64 12"
alias random_mac="openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'"
alias remove_last_line="sed '$d'"
alias show_window_class='xprop | grep CLASS'
alias silent='amixer -q sset "PCM" 0 ; amixer -q sset "MASTER" 0'
alias unsilent='amixer -q sset "PCM" 96 ; amixer -q sset "MASTER" 96'
alias scan_for_wlans="/sbin/iwlist scanning 2>/dev/null | grep -e 'Cell' -e 'Channel\:' -e 'Encryption' -e 'ESSID' -e 'WPA' | sed 's|Cell|\nCell|g'"
alias scan_for_hosts="fping -a -g $(/sbin/ifconfig `/sbin/route -n | grep 'UG ' | head -n1 | awk {'print $8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').1 $(/sbin/ifconfig `/sbin/route -n | grep 'UG '| head -n1 | awk {'print $8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').254 2>/dev/null"
alias whatsmyip="curl -s ip.nu | xargs | html_strip"
alias html_umlaute="sed -e 's|ü|\&uuml;|g' -e 's|Ü|\&Uuml;|g' -e 's|ä|\&auml;|g' -e 's|Ä|\&Auml;|g' -e 's|ö|\&ouml;|g' -e 's|Ö|\&Ouml;|g' -e 's|ß|\&szlig;|g'"
alias html_strip="sed -e 's|<[^>]*>||g'"
alias show_colors="for i in \`seq 1 7 ; seq 30 48 ; seq 90 107\` ; do echo -e \"\e[\${i}mcolor \$i\e[0m\" ; done"
alias clive_mp3="clive --exec='/usr/bin/ffmpeg -y -ab 256k -i %i %o'"
alias patch_from_diff="patch -Np0 -i"
alias speedtest="wget -O- http://cachefly.cachefly.net/200mb.test >/dev/null"
alias pidgin_lastlog="find ~/.purple/logs/ -type f -mtime -1 | xargs tail -n 5"
#alias repo_http2ssh="sed -i 's|^\(.*url.*=\)[ ]*\(http://simon\.psaux\.de.*\)/\(.*\.git\)|\1 ssh://git@psaux.de/\3|g' $(find .git/ -name 'config' | xargs) .gitmodules 2>/dev/null"

alias permissions_normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown ${SUDO_USER:-$USER}: . -R"
alias permissions_web_normalize="chown ${SUDO_USER:-$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:${SUDO_USER:-$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"

alias packages_workstation="cat $( grep '^\.\ ' ~/.packages/workstation.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/workstation.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias packages_laptop="cat $( grep '^\.\ ' ~/.packages/laptop.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/laptop.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias packages_server="cat $( grep '^\.\ ' ~/.packages/server.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/server.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias packages_minimal="cat $( grep '^\.\ ' ~/.packages/minimal.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/minimal.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"

alias t='true'
alias f='false'

if ( grep -q "minit" /proc/cmdline )
then
    alias reboot="sudo minit-shutdown -r &"
    alias halt="sudo minit-shutdown -h &"
fi

if ( grep -q work /etc/hostname ) 
then
    alias scp='scp -l 25000'
    alias windows='rdesktop -kde -a 16 -g 1280x1024 -u sschiele 192.168.80.55'
    alias start_windows='wakeonlan 00:1C:C0:8D:0C:73'
else
    alias start_mediacenter="wakeonlan 00:01:2e:27:62:87"
fi

clive-wrapper-mp3() {
    clive -f best --exec="( echo %f | grep -qi -e 'webm$' -e 'webm\"$' ) && ( ffmpeg -i %f %f.mp3 ; rm -f %f )" $@
}
alias youtube-mp3="clive-wrapper-mp3"

clive-wrapper() {
    clive -f best --exec="( echo %f | grep -qi -e 'webm$' -e 'webm\"$' ) && ( ffmpeg -i %f %f.mp4 ; rm -f %f )" $@
}
alias youtube="clive-wrapper"

# {{{ Prompt

force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] ; then #&& tput setf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

function prompt_func () {
    lastret=$?
    if [[ -e "/usr/local/bin/git_ps1" ]] && [[ -e "/usr/bin/timeout" ]]
    then
        GIT_PS1=$(timeout 1 git_ps1)
    fi
    PS1error=$( test $lastret -gt 0 && echo "${COLOR_BG_RED}[$lastret]${COLOR_NONE} ")
    PS1user="$( test `whoami` == 'root' && echo ${RED})\u${COLOR_NONE}"
    PS1color="$COLOR_BG_GRAY"
    PS1="${PS1error}${COLOR_NONE}${PS1user}@\h $PS1color\w${COLOR_NONE}${GIT_PS1}${COLOR_NONE} > "
}

if [ "$color_prompt" = yes ]; then
    PROMPT_COMMAND=prompt_func
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt
# }}}

# {{{* nodejs
if [ -d $HOME/local/node/ ]
then
    ###-begin-npm-completion-###
    COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
    COMP_WORDBREAKS=${COMP_WORDBREAKS/@/}
    export COMP_WORDBREAKS

    if complete &>/dev/null; then
      _npm_completion () {
        local si="$IFS"
        IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                               COMP_LINE="$COMP_LINE" \
                               COMP_POINT="$COMP_POINT" \
                               npm completion -- "${COMP_WORDS[@]}" \
                               2>/dev/null)) || return $?
        IFS="$si"
      }
      complete -F _npm_completion npm
    elif compctl &>/dev/null; then
      _npm_completion () {
        local cword line point words si
        read -Ac words
        read -cn cword
        let cword-=1
        read -l line
        read -ln point
        si="$IFS"
        IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                           COMP_LINE="$line" \
                           COMP_POINT="$point" \
                           npm completion -- "${words[@]}" \
                           2>/dev/null)) || return $?
        IFS="$si"
      }
      compctl -K _npm_completion npm
    fi
    ###-end-npm-completion-###
    export PATH=$HOME/local/node/bin:$PATH
    export NODE_PATH=$HOME/local/node:$HOME/local/node/lib/node_modules
fi
# }}}

[[ -n  "$( ls ~/.fonts/*-Powerline.* 2>/dev/null )" ]] && export POWERLINE_FONT="true" || export POWERLINE_FONT="false"

