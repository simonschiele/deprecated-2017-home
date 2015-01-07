
[ -z "$PS1" ] || [ -z "$BASH_VERSION" ] && return

# {{{ Includes + PATH

# add local bin-directories to PATH
tmpname="bin .bin .bin-ypsilon .bin-private"
tmpname+=" node_modules/.bin .node_modules/.bin"
for bin in $tmpname ; do
    [ -d ${HOME}/${bin} ] && PATH="${bin/#/${HOME}/}:${PATH}"
done

# source helpers, libs, ...
tmpname="/etc/bash_completion ${HOME}/.private/etc/bashrc"
tmpname+=" ${HOME}/.essentials/essentials.sh"
for include in $tmpname ; do
    if [ -r ${include} ] ; then
        . ${include}
    else
        echo "[WARNING] include ${include} not found" >&2
    fi
done

# source logout scripts
tmpname=".logout .bash_logout .shell_logout"
for include in ; do
    [ -r ${include} ] && trap ${include/#/${HOME}/} 0 && break
done

# verify essentials are loaded
if [ -z "${ESSENTIALS_DIR}" ] ; then
    echo "[ERROR] essentials not loaded" >&2
    export ESSENTIALS=false
else
    export ESSENTIALS=true
fi

# }}}

# {{{ Keybinds

# ctrl+e - remove till last seperator
bind '\C-e:unix-filename-rubout'

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

# detect chroot (doesn't work)
if [ -z "${debian_chroot}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$( cat /etc/debian_chroot )
fi

# cleanup
unset bin include tmpname

