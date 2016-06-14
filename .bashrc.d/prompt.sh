#!/bin/bash
# todo: config flags (icons, enable/disable colors, enable/disable untracked-seperated)
# todo: "pwd"-prolem + flag for "directory context prompt"
# todo: async fetch (after pwd)

function color.exists() {
    [ "${COLORS[${1:-none}]+isset}" ] && return 0 || return 1
}

function color.ps1() {
    ( color.exists "${1:-none}" ) && echo -ne "\[${COLORS[${1:-none}]}\]"
}

function es_prompt_status_git() {
    local gitBranch gitReflogId gitUntracked gitModified gitRemoteBranchExists
    local gitLastlogId ahead modified untracked ok

    if LANG=C git rev-parse --is-inside-work-tree 2>/dev/null >&2 ; then
        gitBranch="$( LANG=C git symbolic-ref -q --short HEAD )"
        gitReflogId="$( LANG=C git reflog --pretty=format:'%h' -1 )"
        gitUntracked="$( git ls-files --other --exclude-standard --directory | egrep -v '/$' | head -n 1 )"
        gitModified="$( git ls-files -m | head -n 1 )"
        gitRemoteBranchExists="$( git branch -r | grep "origin/${gitBranch}$" )"

        if [[ -n "$gitRemoteBranchExists" ]] ; then
            gitLastlogId="$( LANG=C git log --pretty=format:'%h' origin/${gitBranch} -1 )"

            if [[ "${gitReflogId}" != "${gitLastlogId}" ]] ; then
                ahead="$( color.ps1 yellow )↑"
            fi
        else
            ahead="$( color.ps1 yellow )?"
        fi

        if [[ -n "${gitModified}" ]] ; then
            modified="$( color.ps1 red )⚡"
        fi

        if [[ -n "${gitUntracked}" ]] ; then
            untracked="$( color.ps1 red )?"
        fi

        if [[ "${gitBranch}" == 'master' ]] ; then
            gitBranch=""
        else
            gitBranch="$gitBranch "
        fi

        if [[ -z "${ahead}" ]] && [[ -z "${modified}" ]] ; then
            ok="$( color.ps1 green )♥"
        fi
        echo "(${gitBranch}${ok}${modified}${ahead}${untracked}$( color.ps1 none ))"
    fi
}

function es_prompt() {
    local lastret=$?
    local colors PS1prompt PS1error PS1user PS1host PS1path PS1git PS1chroot \
          PS1schroot PS1virtualenv

    colors=${1:-true}
    PS1prompt=" > "
    PS1error=$( [ ${lastret} -gt 0 ] && echo "${lastret}" )
    PS1user="${SUDO_USER:-${USER}}"
    PS1host="\h"
    PS1path="\w"
    PS1git=
    PS1chroot=${debian_chroot:+(chroot:$debian_chroot)}
    PS1schroot=${SCHROOT_CHROOT_NAME:+(schroot:$SCHROOT_CHROOT_NAME)}
    PS1virtualenv=${VIRTUAL_ENV:+(virtualenv:$VIRTUAL_ENV)}

    if ( ${colors} ) ; then
        PS1error=${PS1error:+$( color.ps1 red )${PS1error}$( color.ps1 )}
        PS1path=${PS1path:+$( color.ps1 white_background )${PS1path}$( color.ps1 )}
        PS1path=${PS1path:+$( color.ps1 black )${PS1path}}
        PS1chroot=${PS1chroot:+($( color.ps1 red )chroot$( color.ps1 ))}

        BOOLEAN=(true false)
        IS_SUDO=$( pstree -s "$$" | grep -qi 'sudo' ; echo "${BOOLEAN[$?]}" )
        IS_ROOT=$( [[ "$( id -u )" == 0 ]] && ! ${IS_SUDO} ; echo "${BOOLEAN[$?]}" )
        IS_UID0=$( ${IS_SUDO} || ${IS_ROOT} ; echo "${BOOLEAN[$?]}" )
        IS_SSH=$( pstree -s "$$" | grep -qi 'sshd' ; echo "${BOOLEAN[$?]}" )

        if ${IS_UID0} ; then
            PS1user=${PS1user:+$( color.ps1 red )${PS1user}$( color.ps1 )}
        fi

        if ${IS_SSH} ; then
            PS1host=${PS1host:+$( color.ps1 red )${PS1host}$( color.ps1 )}
        fi
    fi

    if [ -x ~/.bashrc.d/prompt.sh ] && [ -n "$( which timeout )" ] ; then
        PS1git=$( LANG=C timeout 0.1 ~/.bashrc.d/prompt.sh "${colors}" )
        local gitret=$?
        if [ $gitret -eq 124 ] ; then
            PS1git="($( color.ps1 red )git slow$( color.ps1 ))"
        fi
    fi

    PS1error=${PS1error:+[${PS1error}] }
    PS1git=${PS1git:+ ${PS1git}}

    PS1="${PS1error}${PS1chroot}${PS1user}@${PS1host} ${PS1path}${PS1git}${PS1schroot}${PS1virtualenv}${PS1prompt}"
}


if [[ "${0}" != '-bash' ]] && [[ "$( readlink -f "${0}" )" == "$( readlink -f "${BASH_SOURCE[0]}" )" ]] ; then
    # called by exec - give git status with timeout

    declare -g -A COLORS
    COLORS[none]="\e[0m"
    COLORS[black]="\e[0;30m"
    COLORS[red]="\e[0;31m"
    COLORS[green]="\e[0;32m"
    COLORS[yellow]="\e[0;33m"
    COLORS[white_background]="\e[47m"

    es_prompt_status_git "${1:-true}"
else
    # called by source - export PROMPT_COMMAND git prompt if not already set
    if ! ( echo "$PROMPT_COMMAND" | grep -q "es_prompt" ) ; then
        export PROMPT_COMMAND="es_prompt${PROMPT_COMMAND:+ ; ${PROMPT_COMMAND}}"
    fi
fi
