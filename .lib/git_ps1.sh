#!/bin/bash

color=${1:-false}

if ( $color ) ; then
    if [ -e ~/.lib/resources.sh ] ; then
        . ~/.lib/resources.sh
    else
        echo "error: couldn't include resources.sh"
        exit 1
    fi
fi
### {{{ Colors 

if ( ${color} )
then
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
fi

### }}} 

if LANG=C git rev-parse 2>/dev/null ; then
    
    gitStatus="$( LANG=C git status 2>/dev/null )"
    gitBranch="$( LANG=C git branch 2>/dev/null | grep '^*' | sed -e 's|^\*\ *\(.*\)|\1|g' -e 's|[()]||g' )"

    if [[ "${gitBranch}" == 'master' ]] ; then
        gitBranch=""
    fi

    if [[ -n "${gitBranch}" ]] ; then
        gitBranch="${gitBranch} "
    fi

    if [[ ! ${gitStatus} =~ "working directory clean" ]] ; then
        state="${RED}⚡"
    fi

    if [[ "${gitStatus}" =~ "ahead of" ]] ; then
        ahead="${YELLOW}↑"
    fi

    if test -n "${ahead}" || test -n "${state}" ; then
        echo "(${gitBranch}${ahead}${state}${COLOR_NONE})"
    else
        echo "(${gitBranch}${GREEN}♥${COLOR_NONE})"
    fi
fi

