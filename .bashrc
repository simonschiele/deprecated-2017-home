#!/bin/bash

if [ -z "$PS1" ] || [ -z "$BASH_VERSION" ] ; then
    echo "ERROR: shell is not BASH" >&2
    return 1
fi

# {{{ Includes + PATH

# add local bin-directories to PATH
tmpname="bin .bin .bin-ypsilon .bin-pb .bin-private"
tmpname+=" node_modules/.bin .node_modules/.bin .node/bin"
for dir in $tmpname ; do
    [ -d "$HOME"/"$dir" ] && PATH="${dir/#/${HOME}/}:${PATH}"
done

# source helpers, libs, ...
tmpname="/etc/bash_completion ${HOME}/.private/etc/bashrc"
tmpname+=" ${HOME}/.essentials/essentials.sh"
for include in $tmpname ; do
    if [ -r "$include" ] ; then
        . "$include"
    else
        #echo "[WARNING] include ${include} not found" >&2
        echo -n
    fi
done

# verify essentials are loaded
if [ -n "$ESSENTIALS_DIR" ] ; then
    export ESSENTIALS=true

    # if essential debug is enabled, print banner + infos
    if ( "$ESSENTIALS_DEBUG" ) ; then
        es_info
    fi
else
    echo "[ERROR] essentials not loaded, loading failover defaults" >&2
    export ESSENTIALS=false

    # defaults applications
    PAGER=$( which less )
    PAGER=${PAGER:-more}
    EDITOR=$( which vim.nox )
    EDITOR=${EDITOR:-$( which vim )}
    EDITOR=${EDITOR:-$( which vi )}
    EDITOR=${EDITOR:-$( which nano )}
    EDITOR=${EDITOR:-$( which mcedit )}
    EDITOR=${EDITOR:-$( which joe )}
    export EDITOR PAGER

    # applications overwrite
    alias sudo='sudo '
    alias cp='cp -i'
    alias mv='mv -i'
    alias rm='rm -i'

    # <ctrl> + <e> - remove till last seperator
    bind '\C-e:unix-filename-rubout'
fi

# }}}

# {{{ History

export HISTCONTROL=ignoreboth
export HISTFILESIZE=50000
export HISTSIZE=10000
export HISTIGNORE='&:clear:ls:cd:[bf]g:exit:[ t\]*'
# export HISTIGNORE="ls:l:la:ll:clear:pwd:hist:history:tree"
export HOSTFILE="${HOME}/.hosts"
shopt -s histappend
shopt -s cmdhist        # combine multiline

#shopt -s histappend histreedit histverify
#export PROMPT_COMMAND="history -a ; history -n ; $PROMPT_COMMAND"

export HISTFILE="${HOME}/.history"
export MYSQL_HISTFILE="${HOME}/.mysql_history"
export SQLITE_HISTFILE="${HOME}/.sqlite_history"

# }}}

# general settings
set -o notify                       # report status of terminated bg jobs immediately
shopt -s checkjobs                  # print warning if jobs are running on shell exit
shopt -s globstar                   # ** matches all files, dirs and subdirs
shopt -s extglob                    # extended pattern matching features
shopt -s autocd                     # if a command is a dir name, cd to it
shopt -s cdspell                    # correct dir spelling errors on cd
shopt -s dirspell                   # correct dir spelling errors on completion
shopt -s checkwinsize               # check winsize and update LINES + COLUMNS
shopt -s lithist                    # save multi-line commands with newlines
shopt -s cmdhist                    # save multi-line commands in a single hist entry
shopt -s histappend                 # append new history entries
shopt -s progcomp                   # programmable completion
#shopt -s no_empty_cmd_completion    # don't try to complete empty cmds

# detect chroot (doesn't work, need to find a better way...)
if [ -z "${debian_chroot}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$( cat /etc/debian_chroot )
fi

# cleanup
unset dir include tmpname

# can't remember what this was about - most likely java on i3
export DE=generic

echo "[running] $HOME/.bashrc" >&2

