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
export HR="============================================================"

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

alias hr="for i in \$( seq 1 \$COLUMNS ) ; do echo -n '=' ; done ; echo"
alias t="true"
alias f="false"

alias debian_version="lsb_release -a"
alias debian_packages_minimal="cat \$( grep '^\.\ ' ~/.packages/minimal.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/minimal.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias debian_packages_server="cat \$( grep '^\.\ ' ~/.packages/server.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/server.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias debian_packages_workstation="cat \$( grep '^\.\ ' ~/.packages/workstation.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/workstation.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias debian_packages_laptop="cat \$( grep '^\.\ ' ~/.packages/laptop.list | sed 's|^\. *||g' | sed 's|^|\~/\.packages/|g' | xargs ) ~/.packages/laptop.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' | xargs"
alias debian_packages_list_by_size="dpkg-query -W --showformat='\${Installed-Size;10}\t\${Package}\n' | sort -k1,1n"
alias debian_packages_list_configfiles="dpkg-query -f '\n\n\${Package} \n\${Conffiles}' -W"
alias debian_packages_list_experimental='aptitude -t experimental search -F "%p %?V %?v %?t" --disable-columns .|grep -v none| grep experimental| awk "{if( \$2 == \$3) print \$1}"'
alias debian_packages_list_unstable="aptitude -t unstable search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep unstable| awk '{if( \$2 == \$3) print \$1}'"
alias debian_packages_list_testing="aptitude -t testing search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep testing| awk '{if( \$2 == \$3) print \$1}'"
alias debian_packages_list_stable="aptitude -t stable search -F '%p %?V %?v %?t' --disable-columns .|grep -v none| grep stable| awk '{if( \$2 == \$3) print \$1}'"

alias hooks_run="eval \$( grep ^systemtype= ~/.system.conf ) find ~/.hooks/* | while read hook ; do if (( grep -iq -e ^hook_systemtype.*\${systemtype} \$hook ) && ( grep -iq ^hook_optional.*false \$hook )) ; then ~/.hooks/loader.sh \$hook ; fi ; done"
alias repo_compare="[ \"x\${repo}\" == \"x\" ] && ( echo 'Please export \$repo variable like:' ; echo 'export \$repo=\"dot.vim.git\"' ; exit 1 ) || ( mkdir \$repo/ ; cd \$repo ; git clone http://simon.psaux.de/git/\${repo} psaux/ ; git clone https://github.com/simonschiele/\${repo} github/ ; echo \"psaux\" ; cd psaux/ ; git plog | head -n 11 ; echo -e \"\ngithub\" ; cd ../github/ ; git plog | head -n 10 ; cd ../../ )"
#alias repo_http2ssh="sed -i 's|^\(.*url.*=\)[ ]*\(http://simon\.psaux\.de.*\)/\(.*\.git\)|\1 ssh://git@psaux.de/\3|g' $(find .git/ -name 'config' | xargs) .gitmodules 2>/dev/null"

alias permissions_normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown ${SUDO_USER:-$USER}: . -R"
alias permissions_normalize_web="chown ${SUDO_USER:-$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:${SUDO_USER:-$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"
alias permissions_normalize_system="chown ${SUDO_USER:-$USER}: ~/ -R ; find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;"

alias grep_ip='grep -o '"'"'\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'"'"
alias grep_urls="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias random_password="openssl rand -base64 12"
alias random_mac="openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'"
alias random_ip="nmap -iR 1 -sL -n | grep_ip -o"
alias scan_for_wlans="/sbin/iwlist scanning 2>/dev/null | grep -e 'Cell' -e 'Channel\:' -e 'Encryption' -e 'ESSID' -e 'WPA' | sed 's|Cell|\nCell|g'"
alias scan_for_hosts="fping -a -g \$(/sbin/ifconfig `/sbin/route -n | grep 'UG ' | head -n1 | awk {'print $8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').1 \$(/sbin/ifconfig `/sbin/route -n | grep 'UG '| head -n1 | awk {'print \$8'}` | grep -i 'inet' | cut -f'2' -d':' | cut -f'1' -d' ' | cut -f'1-3' -d'.').254 2>/dev/null"
alias remove_last_line="sed '\$d'"
alias html_umlaute="sed -e 's|ü|\&uuml;|g' -e 's|Ü|\&Uuml;|g' -e 's|ä|\&auml;|g' -e 's|Ä|\&Auml;|g' -e 's|ö|\&ouml;|g' -e 's|Ö|\&Ouml;|g' -e 's|ß|\&szlig;|g'"
alias html_strip="sed -e 's|<[^>]*>||g'"
alias show_window_class='xprop | grep CLASS'
alias patch_from_diff="patch -Np0 -i"
alias silent='amixer -q sset "PCM" 0 ; amixer -q sset "MASTER" 0'
alias unsilent='amixer -q sset "PCM" 96 ; amixer -q sset "MASTER" 96'
alias show_colors="for i in \`seq 1 7 ; seq 30 48 ; seq 90 107\` ; do echo -e \"\e[\${i}mcolor \$i\e[0m\" ; done"
alias screenshot="import -display :0 -window root screenshot-\$(date +%Y-%m-%d_%s).png"
alias mplayer_left="mplayer -xineramascreen 0" 
alias mplayer_right="mplayer -xineramascreen 1" 

convert2() { ext=${1} ; shift ; for file ; do echo -n ; [ -e "$file" ] && ( echo -e "\n\n[CONVERTING] ${file} ==> ${file%.*}.${ext}" && ffmpeg -loglevel error -i "${file}" -strict experimental "${file%.*}.${ext}" && echo rm -i "${file}" ) || echo "[ERROR] File not found: ${file}" ; done }
alias convert2audio="convert2 mp3"
alias youtube-mp3="clive -f best --exec=\"echo >&2; echo '[CONVERTING] %f ==> MP3' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp3 && rm -i %f\""
alias youtube="clive -f best --exec=\"( echo %f | grep -qi -e 'webm$' -e 'webm.$' ) && ( echo >&2 ; echo '[CONVERTING] %f ==> MP4' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp4 && rm -f %f )\""

alias whatsmyip="wget -O- -q ip.nu | xargs | html_strip"
alias speedtest="wget -O- http://cachefly.cachefly.net/200mb.test >/dev/null"

alias find_last_edited="find . -type f -printf \"%T@ %T+ %p\n\" | sort -n"
alias pidgin_lastlog="find ~/.purple/logs/ -type f -mtime -1 | xargs tail -n 5"
alias sickbeard_skipped="sudo grep 'Found result' /var/log/sickbeard/sickbeard* | sed 's|\(.*\):\(.*[0-9]\:[0-9][0-9]\:[0-9][0-9]\).*\:\:\(.*\)\(at http.*\)|\2 - \3|g'"

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

alias route_via_wlan="for i in \`seq 1 10\` ; do route del default 2>/dev/null ; done ; route add default eth0 ; route add default wlan0 ; route add default gw \"\$( /sbin/ifconfig wlan0 | grep_ip | head -n 1 | cut -f'1-3' -d'.' ).1\""
#nrg2iso() { dd bs=1k if="$1" of="$2" skip=300 }

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

#[[ $- == *i* ]]   &&   . ~/.lib/git-prompt/git-prompt.sh

#trap "$HOME/.logout" 0

