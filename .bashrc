#!/bin/bash

function verify_bash() {
    # test if shell is bash
    if [[ -z "$PS1" ]] || [[ -z "$BASH_VERSION" ]] ; then
        echo "ERROR: shell is not BASH" >&2
        return 1
    fi

    # test if interactive
    [[ "$-" != *i* ]] && return 1

    return 0
}

function setup_profile() {
    if ! shopt -q login_shell && [[ "$-" == *i* ]] ; then
        [ -r /etc/profile ] && . /etc/profile
    fi
}

function setup_path() {
    local possible_bins dir

    possible_bins=( .bin bin )
    for dir in "${possible_bins[@]}" ; do
        [ -d "$HOME"/"$dir" ] && PATH="${dir/#/${HOME}/}:${PATH}"
    done

    export CDPATH="~:repos"
}

function setup_includes() {
    local include

    for include in "$HOME"/.bashrc.d/*.sh "$HOME"/.private/bashrc ; do
        if [[ ! -e "$include" ]] ; then
            echo "[WARNING] include '$HOME/$include' not found" >&2
            continue
        fi
        . "$include" || echo "[WARNING] Error while including ${include}" >&2
    done
}

function setup_history() {
    export HISTFILE="${HOME}/.bash_history"
    export MYSQL_HISTFILE="${HOME}/.mysql_history"
    export SQLITE_HISTFILE="${HOME}/.sqlite_history"

    export HISTCONTROL="ignoreboth:erasedups"
    export HISTSIZE=5000
    export HISTFILESIZE=20000
    export HISTIGNORE='&:clear:ls:[bf]g:exit:hist:history:tree:w: '
    export HISTTIMEFORMAT='%F %T '
    shopt -s histappend
    shopt -s cmdhist        # combine multiline

    # sync history between all terminals
    # export PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"
}

function setup_completion() {
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
}

function setup_colors() {
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
        eval "$( dircolors -b )"

        # dircolors (solarized)
        if [ -r ~/.lib/dircolors-solarized/dircolors.256dark ] ; then
            eval "$( dircolors ~/.lib/dircolors-solarized/dircolors.256dark )"
        fi
    fi
}

function setup_ssh() {
    # siehe auch:
    # https://gist.github.com/octocat/2a6851cde24cdaf4b85b 

    ### Test whether you have a running agent.
    #$ ssh-add -l >& /dev/null; [ $? = 2 ] && echo no-agent
    #no-agent
    ### If not, start one.
    #$ eval $(ssh-agent)
    ### Now, add your key to the agent.
    #$ ssh-add

    if [ -n "$SSH_AGENT_PID" ] && ps "$SSH_AGENT_PID" 2>/dev/null >&2 ; then
        # found, running and exported - all fine
        echo -n
    elif ( pgrep -u "${SUDO_USER:-$USER}" ssh-agent >/dev/null ) ; then
        # reuse already running agent for active user
        SSH_AGENT_PID=$( ps -U "${SUDO_USER:-$USER}" | awk '{print $1}' | tail -n1 )
    elif [ -z "${SSH_AGENT_PID}" ] || ! ( ps "${SSH_AGENT_PID}" >/dev/null ) ; then
        echo "no ssh-agent detected - starting new one" >&2
        SSH_AGENT_PID=$( eval "$( ssh-agent )" | grep -o "[0-9]*" )
    fi
    export SSH_AGENT_PID

    if [ -e /usr/lib/openssh/gnome-ssh-askpass ] ; then
        export SUDO_ASKPASS=/usr/lib/openssh/gnome-ssh-askpass
    fi
}

function setup_x11() {
    # If $DISPLAY is not set, try to find running xserver and export it
    if [ -z "${DISPLAY}" ] ; then
        if ( pidof Xorg >/dev/null || pidof X >/dev/null ) ; then
            DISPLAY=:$( ps ax | grep -i -e Xorg -e "/usr/bin/X" | grep -o " :[0-9]* " | head -n 1 | grep -o "[0-9]*" )
            DISPLAY=${DISPLAY:-:0}
            export DISPLAY
        fi
    fi
}

function setup_applications() {
    local browser='chromium, google-chrome, google-chrome-unstable, chrome, '
          browser+='iceweasel, firefox, epiphany, opera, dillo'
    local mailer='icedove, thunderbird'
    local terminals='terminator, gnome-terminal, rxvt-unicode, rxvt, xterm'
    local editors='vim.nox, vim, vi, emacs -nw, nano, joe, mcedit'
    local x11_editors='gvim, vim.gnome, gedit, emacs, mousepad'

    OPEN='gnome-open'
    BROWSER="$( es_depends_first "$browser" )"
    MAILER="$( es_depends_first "$mailer" )"
    TERMINAL="$( es_depends_first "$terminals" )"
    EDITOR="$( es_depends_first "$editors" )"
    VISUAL="$( es_depends_first "$x11_editors" )"
    SUDO_EDITOR="$EDITOR"
    GIT_EDITOR="$EDITOR"
    SVN_EDITOR="$EDITOR"
    TZ="${TZ:-$( head -n1 /etc/timezone )}"
    TZ="${TZ:-Europe/Berlin}"

    if es_depends "less" ; then
        PAGER="less -i"
        MANPAGER="less -X"   # no clear afterwards
    else
        PAGER="more"
        MANPAGER="more"
    fi

    export OPEN BROWSER MAILER TERMINAL EDITOR VISUAL SUDO_EDITOR \
           GIT_EDITOR SVN_EDITOR TZ PAGER MANPAGER

    alias cp='cp -i -r'
    alias grep='grep --color=auto'
    alias ls='LC_COLLATE=C ls --color=auto --group-directories-first -p'
    alias mkdir='mkdir -p'
    alias mv='mv -i'
    alias rm='rm -i'
    alias screen='screen -U'
    alias sudo='sudo '
    alias tmux='TERM=screen-256color-bce tmux'
    alias vi='$EDITOR'
    alias wget='wget -c'
}

function setup_keymapping() {
    # ctrl + e - remove till last seperator (overwrites a keymapping to jump to line end)
    bind '\C-e:unix-filename-rubout'
}

function setup_shell() {
    shopt -s autocd                     # if a command is a dir name, cd to it
    shopt -s cdspell                    # correct dir spelling errors on cd
    shopt -s checkjobs                  # print warning if jobs are running on shell exit
    shopt -s checkwinsize               # check winsize and update LINES + COLUMNS
    shopt -s dirspell                   # correct dir spelling errors on completion
    shopt -s extglob                    # extended pattern matching features
    shopt -s globstar                   # ** matches all files, dirs and subdirs
    shopt -s lithist                    # save multi-line commands with newlines
    shopt -s progcomp                   # programmable completion
    shopt -u no_empty_cmd_completion    # don't try to complete empty cmds
    set -o noclobber                    # do not overwrite files by redirect
    set -o notify                       # report status of terminated bg jobs immediately
}

function stamp() {
    date +%s%N | cut -b1-13
}

function bashrc() {
    local status=0

    verify_bash || return $?
    setup_profile

    setup_path || status=$(( "$status" +1 ))
    setup_includes || status=$(( "$status" + 1 ))
    setup_history
    setup_completion
    setup_colors
    setup_ssh
    setup_x11
    setup_applications
    setup_keymapping
    setup_shell

    unset -f verify_bash setup_colors setup_completion setup_history \
             setup_includes setup_path setup_ssh setup_x11 \
             setup_applications bashrc

    return $status
}

bashrc "$@" || return $?
