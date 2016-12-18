#!/bin/bash
# old stuff from bashrc when switching to loader
# remove this one asap

function stamp() {
    date +%s%N | cut -b1-13
}


function setup_profile() {
    if ! shopt -q login_shell && [[ "$-" == *i* ]] ; then
        [ -r /etc/profile ] && . /etc/profile
    fi
}

function setup_config() {
    local directory

    if [[ ! -d "$directory" ]] ; then
        echo "[WARNING] Directory not found '$directory'" >&2
    fi

    for file in .bashrc bashrc ; do
        echo "testing for $directory/$file"
        if [[ -r "$directory/$file" ]] ; then
            echo "found"
            . "$directory/$file" \
                || echo "[WARNING] Error while including '$directory/$file'"
        fi
    done

    shopt -s nullglob
    for include in "$directory"/.bashrc.d/*.{sh,bash,completion} \
                   "$directory"/bashrc.d/*.{sh,bash,completion} ; do
        if [[ ! -x "$include" ]] ; then
            echo "[WARNING] include '$HOME/$include' not found or deactivated" >&2
            continue
        fi
        . "$include" || echo "[WARNING] Error while including ${include}" >&2
    done
    shopt -u nullglob
}

function setup_path() {
    local possible_bins dir

    possible_bins=( .bin bin )
    for dir in "${possible_bins[@]}" ; do
        [ -d "$HOME"/"$dir" ] && PATH="${dir/#/${HOME}/}:${PATH}"
    done

    export CDPATH=".:~"
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
    shopt -s histappend
    shopt -s cmdhist        # combine multiline

    export HISTSIZE=5000
    export HISTFILESIZE=
    export HISTCONTROL="ignoreboth:erasedups"
    export HISTIGNORE='&:clear:ls:[bf]g:exit:hist:history:tree:w: '
    export HISTTIMEFORMAT='%F %T '

    if [[ -f ~/.history ]] ; then
        mv -f ~/.history{,~}
        mkdir -p ~/.history
        mv -v ~/.history{~,/bash}
    fi

    if [[ ! -d ~/.history ]] && ! mkdir -p ~/.history 2>/dev/null ; then
        echo "[WARNING] Couldn't create '$HOME/.history'" >&2
        return 1
    fi

    local hist histories
    histories=( bash less psql mysql sqlite )
    for hist in ${histories[*]} ; do
        cat ~/.*"${hist}"*h*st* >> ~/.history/"$hist" 2>/dev/null
        rm -f ~/.*"${hist}"*h*st* 2>/dev/null
    done

    export HISTFILE="${HOME}/.history/bash"
    export LESSHISTFILE="${HOME}/.history/less"
    export PSQL_HISTORY="${HOME}/.history/psql"
    export MYSQL_HISTFILE="${HOME}/.history/mysql"
    export SQLITE_HISTFILE="${HOME}/.history/sqlite"

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

    # lookup file for hostname completion
    export HOSTFILE="$HOME/.history/hosts"
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

function es_depends() {
    local depends_name="$1"
    local depends_type="${2:-bin}"
    local available=false

    case "$depends_type" in
        bin|which|executable)
            which "$depends_name" >/dev/null && available=true
            ;;

        dpkg|deb|debian)
            es_depends dpkg || exit_error 'please install dpkg if you want to check depends via dpkg'
            dpkg -l | grep -iq "^ii\ \ ${depends_name}\ " && available=true
            ;;

        pip)
            local pip_version pip_output
            es_depends pip || exit_error 'please install (python-)pip, to check depends via pip'

            pip_version=$( pip --version | awk '{print $2}' )
            if ( es_check_version 1.3 "$pip_version" ) ; then
                pip_output=$( pip show "$depends_name" 2>/dev/null | xargs | awk '{print $3"=="$5}' | sed '/^==$/d' )
            else
                pip_output=$( pip freeze 2>/dev/null | grep "^${depends_name}=" )
            fi

            [[ -n "$pip_output" ]] && available=true
            ;;

        *)
            es_depends "$depends_name" bin && available=true
            ;;
    esac

    $available
    return
}

function es_depends_first() {
    local candidate candidate_cmd
    local candidates="$*"
    IFS=","

    for candidate in $candidates ; do
        candidate="${candidate##*( )}"
        candidate="${candidate%%*( )}"
        candidate_cmd=$( echo "$candidate" | cut -f'1' -d' ' )
        if es_depends "$candidate_cmd" ; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
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
            DISPLAY=$( pgrep -nfa Xorg 2>&1 | sed 's|.* \(:[0-9]\+\).*|\1|g' )
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
    TZ="${TZ:-$( head -n1 /etc/timezone )}"
    TZ="${TZ:-Europe/Berlin}"

    EDITOR="$( es_depends_first "$editors" )"
    VISUAL="$( es_depends_first "$x11_editors" )"
    SUDO_EDITOR="$EDITOR"
    GIT_EDITOR="$EDITOR"
    SVN_EDITOR="$EDITOR"
    PSQL_EDITOR="$EDITOR"
    PSQL_EDITOR_LINENUMBER_ARG='+'

    if es_depends "less" ; then
        PAGER="less -i"
        MANPAGER="less -X"   # no clear afterwards
    else
        PAGER="more"
        MANPAGER="more"
    fi

    export OPEN BROWSER MAILER TERMINAL EDITOR VISUAL SUDO_EDITOR \
           GIT_EDITOR SVN_EDITOR TZ PAGER MANPAGER PSQL_EDITOR \
           PSQL_EDITOR_LINENUMBER_ARG

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
    set -o notify                       # report status of terminated bg jobs immediately
    #set -o noclobber                   # do not overwrite files by redirect
}

setup_history
setup_completion
setup_colors
setup_ssh
setup_x11
setup_applications
setup_keymapping
setup_shell
