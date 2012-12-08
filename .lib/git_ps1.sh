#!/bin/bash

if [ -n "${1}" ]
then
    color=${1}
else
    color=false
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

### {{{ is_git() 

is_git () {
    
    REPO="`pwd`"

    until [[ "$CHECKED" == '/' ]]
    do
        if [[ -d "${REPO}/.git" ]]
        then
            exit 0
        fi
        CHECKED="${REPO}"
        REPO=`dirname "${REPO}"`
    done
    
    exit 1
}

### }}} 

if ( is_git )
then
    gitStatus="$(git status 2>&1)"
    gitBranch="$(git branch 2>&1 | grep "^*" | sed -e 's|^*\ ||g' -e 's|[()]||g' )"
    
    if [[ $gitBranch == 'master' ]]
    then
        gitBranch=""
    fi
    
    if [[ -n "${gitBranch}" ]]
    then
        gitBranch="${gitBranch} "
    fi

    if [[ ! ${gitStatus} =~ "working directory clean" ]]
    then
        state="${RED}⚡"
    fi
    
    if ( echo "$gitStatus" | grep -q "ahead of" )
    then
        ahead="${YELLOW}↑"
    fi

    if test -n "${ahead}" || test -n "${state}"
    then
        echo "(${gitBranch}${ahead}${state}${COLOR_NONE})"
    else
        echo "(${gitBranch}${GREEN}♥${COLOR_NONE})"
    fi
fi

