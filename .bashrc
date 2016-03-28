#!/bin/bash

# test if shell is bash
if [ -z "$PS1" ] || [ -z "$BASH_VERSION" ] ; then
    echo "ERROR: shell is not BASH" >&2
    return 1
fi

# test if interactive
case $- in
    *i*) ;;
    *) return ;;
esac

# {{{ PATH + Includes

# add local bin-directories to PATH
possible_bins="node_modules/.bin .node_modules/.bin .node/bin bin .bin"
for dir in $possible_bins ; do
    [ -d "$HOME"/"$dir" ] && PATH="${dir/#/${HOME}/}:${PATH}"
done
unset dir possible_bins

# source helpers, libs, ...
mandatory_includes="${HOME}/.bash_functions ${HOME}/.bash_prompt"
mandatory_includes+=" ${HOME}/.bash_aliases ${HOME}/.private/bashrc"
for include in $mandatory_includes ; do
    if [ -r "$include" ] ; then
        . "$include" || echo "[WARNING] Error while including ${include}" >&2
    else
        echo "[WARNING] Couldn't read/find ${include}" >&2
    fi
done
unset include mandatory_includes

# }}}

# {{{ History

export HISTFILE="${HOME}/.bash_history"
export MYSQL_HISTFILE="${HOME}/.mysql_history"
export SQLITE_HISTFILE="${HOME}/.sqlite_history"

export HISTCONTROL="ignoreboth:erasedups"
export HISTSIZE=500000
export HISTFILESIZE=100000
export HISTIGNORE='&:clear:ls:[bf]g:exit:hist:history:tree:[ t\]*'
export HISTTIMEFORMAT='%F %T '
shopt -s histappend
shopt -s cmdhist        # combine multiline

# sync history between all terminals
# export PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"

# }}}

# {{{ Completion

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# completion case insensitive
bind "set completion-ignore-case on"

# treat hyphens and underscores as equivalent
bind "set completion-map-case on"

# display matches for ambiguous patterns at first tab press
bind "set show-all-if-ambiguous on"

# }}}

# {{{ SSH

if [ -n "$SSH_AGENT_PID" ] && ps "$SSH_AGENT_PID" 2>/dev/null >&2 ; then
    # found, running and exported - all fine
    echo -n
elif ( ps -U "${ESSENTIALS_USER}" | grep -v grep | grep -q ssh-agent ) ; then
    # reuse already running agent for active user
    export SSH_AGENT_PID=$( ps -U "${ESSENTIALS_USER}" | awk {'print $1'} | tail -n1 )
elif [ -z "${SSH_AGENT_PID}" ] || ! ( ps ${SSH_AGENT_PID} >/dev/null ) ; then
    echo "no ssh-agent detected - starting new one"
    export SSH_AGENT_PID=$( eval `ssh-agent` | grep -o "[0-9]*" )
fi

# }}}

# {{{ Colors

# application colors
export GREP_COLOR='7;34'

export LESS_TERMCAP_mb=$'\e[01;31m'
export LESS_TERMCAP_md=$'\e[01;37m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;43;37m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[01;32m'

es_depends "colordiff" && alias diff='colordiff'
es_depends "pacman" && alias pacman='pacman --color=auto'

# dircolors
if es_depends dircolors ; then
    eval "`dircolors -b`"

    # dircolors (solarized)
    if [ -r ~/.lib/dircolors-solarized/dircolors.256dark ] ; then
        eval "`dircolors ~/.lib/dircolors-solarized/dircolors.256dark`"
    fi
fi

# }}}

# {{{ X11

if [ -z "${DISPLAY}" ] ; then
    if ( pidof Xorg >/dev/null || pidof X >/dev/null ) ; then
        DISPLAY=:$( ps ax | grep -i -e Xorg -e "/usr/bin/X" | grep -o " :[0-9]* " | head -n 1 | grep -o "[0-9]*" )
        DISPLAY=${DISPLAY:-:0}
        export DISPLAY
    fi
fi

# }}}

# {{{ Settings

## verify expected ~/.bash_functions is loaded
if [ -n "$ESSENTIALS_HOME" ] ; then
    export ESSENTIALS=true

    # if essential debug is enabled, print banner + infos
    if ( "$ESSENTIALS_DEBUG" ) ; then
        es_info
    fi

    # default applications
    export PAGER=${CONFIG['pager']:-$( es_depends_first "less more" )}
    export BROWSER=${CONFIG['browser']:-$( es_depends_first "chromium iceweasel" )}
    export MAILER=${CONFIG['mailer']:-icedove}
    export OPEN=${CONFIG['open']:-gnome-open}
    export VISUAL=${CONFIG['visual']:-$( es_depends_first "gvim gedit" )}
    export EDITOR=${CONFIG['editor']:-$( es_depends_first "vim.nox vim vi nano" )}

    terminals="terminator gnome-terminal rxvt-unicode xfce-terminal rxvt xterm"
    export TERMINAL=${CONFIG['terminal']:-$( es_depends_first "$terminals" )}
    unset terminals

else
    echo "[ERROR] essentials not loaded, loading failover defaults" >&2
    export ESSENTIALS=false

    # defaults applications
    PAGER=${CONFIG[pager]:-$( which less more | head -n 1 )}
    EDITOR=${CONFIG[editor]:-$( which vim.nox vim vi nano mcedit joe | head -n1 )}
    export EDITOR PAGER

    # applications overwrite
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# general settings
shopt -s checkjobs                  # print warning if jobs are running on shell exit
shopt -s globstar                   # ** matches all files, dirs and subdirs
shopt -s extglob                    # extended pattern matching features
shopt -s autocd                     # if a command is a dir name, cd to it
shopt -s cdspell                    # correct dir spelling errors on cd
shopt -s dirspell                   # correct dir spelling errors on completion
shopt -s checkwinsize               # check winsize and update LINES + COLUMNS
shopt -s lithist                    # save multi-line commands with newlines
shopt -s progcomp                   # programmable completion
#shopt -s no_empty_cmd_completion   # don't try to complete empty cmds
set -o notify                       # report status of terminated bg jobs immediately

# ctrl+e - remove till last seperator
bind '\C-e:unix-filename-rubout'

# }}}

# application overwrites
alias cp='cp -i -r'
alias ls='LC_COLLATE=C ls --color=auto --group-directories-first -p'
alias mkdir='mkdir -p'
alias mv='mv -i'
alias rm='rm -i'
alias screen='screen -U'
alias sudo='sudo '
alias tmux='TERM=screen-256color-bce tmux'
alias wget='wget -c'

