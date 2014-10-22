
[ -z "$PS1" ] || [ -z "$BASH_VERSION" ] && return

# {{{ Includes + PATH

# add local bins to PATH
for bin in bin .bin .bin-ypsilon .bin-private ; do
    [ -d ${HOME}/${bin} ] && PATH="${bin/#/${HOME}/}:${PATH}"
done
unset bin 

# source helpers, libs, ...
for include in ~/.lib/resources.sh ~/.lib/functions.sh /etc/bash_completion ~/.lib/aliases.sh ; do
    [ -r ${include} ] && . ${include}
done

# source logout
for include in .logout .bash_logout .shell_logout ; do
    [ -r ${include} ] && trap ${include/#/${HOME}/} 0 && break
done
unset include 

# color fixing trap
trap 'echo -ne "\e[0m"' DEBUG

# fix old-style ~/.system.conf
if [ -r ~/.system.conf ] && ( grep -v "^system_hostname\|^system_domain\|^system_type\|^system_username" ~/.system.conf | grep -q "^[A-Za-z]" ) ; then
    echo -ne "$( color yellow )DEBUG:$( color ) Fixing old-style ~/.system.conf\t"
    ( sed -e 's|^hostname=|system_hostname=|g' \
          -e 's|^domain=|system_domain=|g' \
          -e 's|^systemtype=|system_type=|g' \
          -e 's|^username=|system_username=|g' \
          -e '/^#\|^system\_/! s|^|#|g' \
          -i ~/.system.conf ) && color.echo "green" "DONE" || color.echo "red" "FAILED"
fi

# loading ~/.system.conf
[ -r ~/.system.conf ] && . ~/.system.conf 

# }}}

# {{{ General Settings

# Vim navigation mode (use ESC)
#set -o vi      

# report status of terminated bg jobs immediately
set -o notify   

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# detect chroot (doesn't work)
if [ -z "${debian_chroot}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$( cat /etc/debian_chroot )
fi

# history
export HISTCONTROL=ignoreboth
export HISTFILESIZE=50000
export HISTSIZE=10000
export HISTIGNORE='&:clear:ls:cd:[bf]g:exit:[ t\]*'
# export HISTIGNORE="ls:l:la:ll:clear:pwd:hist:history:tree"
export HOSTFILE=$HOME/.hosts
shopt -s histappend
shopt -s cmdhist        # combine multiline
# shopt -s histappend histreedit histverify
export PROMPT_COMMAND='history -a; history -n; $PROMPT_COMMAND'

[ -z $HISTFILE ] && export HISTFILE="${HOME}/.history";
[ -z $MYSQL_HISTFILE ] && export MYSQL_HISTFILE="${HOME}/.mysql_history";
[ -z $SQLITE_HISTFILE ] && export SQLITE_HISTFILE="${HOME}/.sqlite_history";

# shell options
shopt -s extglob                    # extended pattern matching features
shopt -s progcomp                   # programmable completion
shopt -s cdspell                    # correct dir spelling errors on cd
shopt -s lithist                    # save multi-line commands with newlines
shopt -s cmdhist                    # save multi-line commands in a single hist entry
shopt -s checkwinsize               # check the window size after each command
shopt -s no_empty_cmd_completion    # don't try to complete empty cmds
shopt -s histappend                 # append new history entries
if [ "$UNAME" != 'Darwin' ]; then
    shopt -s autocd                 # if a command is a dir name, cd to it
    shopt -s checkjobs              # print warning if jobs are running on shell exit
    shopt -s dirspell               # correct dir spelling errors on completion
    shopt -s globstar               # ** matches all files, dirs and subdirs
fi


# }}}

# {{{ Coloring

export TERM='xterm-256color'
export CLICOLOR=1

# Color support detection + color count (warning! crap!)
if [ -x /usr/bin/tput ] && ( tput setaf 1 >&/dev/null ) ; then
    color_support=true
else
    color_support=false
fi

if ( $color_support ) && [[ "$TERM" =~ "xterm" ]] ; then
    if [[ -n "$XTERM_VERSION" ]]; then
        # xterm
        COLORCOUNT='256'
    else
        if [[ $COLORTERM =~ "gnome-terminal" ]] ; then
            # gnome-terminal
            COLORCOUNT='256'
        else
            # xterm compatible
            COLORCOUNT='256'
        fi
    fi
elif [[ "$TERM" =~ "linux" ]] ; then
    # tty
    COLORCOUNT='8'
elif [[ "$TERM" =~ "rxvt" ]] ; then
    # rxvt
    COLORCOUNT=`tput colors`
elif [[ "$TERM" =~ "screen*" ]] ; then
    # screen or tmux
    COLORCOUNT='8'
else
    # unknown
    COLORCOUNT='8'
fi

export COLORCOUNT=${COLORCOUNT:-8}

# dircolors
if [ -x /usr/bin/dircolors ] ; then
    eval "`dircolors -b`"
fi

# dircolors (solarized)
if [ -r ~/.lib/dircolors-solarized/dircolors.256dark ] ; then
    eval "`dircolors ~/.lib/dircolors-solarized/dircolors.256dark`"
fi

# grep/less/diff/... coloring
alias ls='ls --color=auto'
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='7;34'                # green-bold
export LESS_TERMCAP_mb=$'\e[01;31m'     # red-bold
export LESS_TERMCAP_md=$'\e[01;37m'     # white-bold
export LESS_TERMCAP_me=$'\e[0m'         
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;43;37m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[01;32m'
( which colordiff >/dev/null ) && alias diff='colordiff'
( which pacman >/dev/null ) && alias pacman='pacman --color=auto'

# }}}

# {{{ Prompt

function prompt_func() {
    local lastret=$?
        
    PS1error=$( [ ${lastret} -gt 0 ] && echo "[${lastret}] " )
    PS1user=${SUDO_USER:-${USER}}
    PS1host="\h"
    PS1path="\w"

    if ( $color_support ) ; then
        PS1error=$( color.ps1 red )${PS1error}$( color.ps1 )
        PS1user=$( [ $( id -u ) -eq 0 ] && color.ps1 red )${col}${PS1user}$( color.ps1 )
        PS1host=$( pstree -s "$$" | grep -qi 'ssh' && color.ps1 red )${PS1host}$( color.ps1 )
        PS1path=$( color.ps1 black )$( color.ps1 white_background )${PS1path}$( color.ps1 )
    fi
    
    if [ -e ~/.lib/git_ps1.sh ] && [ -n "$( which timeout )" ] ; then
        PS1git=$( LANG=C timeout 0.5 ~/.lib/git_ps1.sh ${color_support} )
        local gitret=$?
        [ $gitret -eq 124 ] && PS1git="($( color.ps1 red )git slow$( color.ps1 ))"
    else
        PS1git=
    fi

    PS1git=${PS1git:+ ${PS1git}}
    PS1chroot=
    PS1prompt=" > "

    PS1="${PS1error}${PS1chroot}${PS1user}@${PS1host} ${PS1path}${PS1git}${PS1prompt}"
}

PROMPT_COMMAND=prompt_func

# }}}

# {{{ vim

EDITOR=$( which vim.nox )
EDITOR=${EDITOR:-$( which vim )}
EDITOR=${EDITOR:-$( which vi )}
EDITOR=${EDITOR:-$( which nano )}
export EDITOR

alias vim.blank="${EDITOR} -N -u NONE -U NONE"
alias vim.bigfile=vim.blank

# check if powerline patched font for vim is available
if ( ls ~/.fonts/P*Pro/*owerline.ttf 2>/dev/null >&2 ) ; then
    export POWERLINE_FONT='true'
else
    export POWERLINE_FONT='false'
fi

# }}}

# {{{ git 

if [ -r ~/.lib/git-flow-completion/git-flow-completion.bash ] ; then
    . ~/.lib/git-flow-completion/git-flow-completion.bash
fi

if [ "$( whereami )" = "work" ] ; then
    GIT_COMMITTER_EMAIL='simon.schiele@ypsilon.net'
    GIT_AUTHOR_EMAIL='simon.schiele@ypsilon.net'
else
    GIT_COMMITTER_EMAIL='simon.codingmonkey@googlemail.com'
    GIT_AUTHOR_EMAIL='simon.codingmonkey@googlemail.com'
fi
GIT_COMMITTER_NAME='Simon Schiele'
GIT_AUTHOR_NAME='Simon Schiele'

# }}}

