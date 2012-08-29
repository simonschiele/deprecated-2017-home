#!/bin/bash

### {{{ Colors 
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
### }}} 


is_git () {
    REPO="`pwd`"

    until [[ "$CHECKED" == '/' ]]
    do
        if [[ -z "$IGNORE" && -e "${REPO}/.gitignore" ]]
        then
            IGNORE="${REPO}/.gitignore"
        fi
        
        if [[ -d "${REPO}/.git" ]]
        then
            exit 0
        fi
        CHECKED="$REPO"
        REPO=`dirname "$REPO"`
    done

    exit 1
}

if ( is_git )
then
    gitStatus="$(git status 2>&1)"
    gitBranch="$(git branch 2>&1 | grep "^*" | awk {'print $2'})"
    
    if [[ $gitBranch == 'master' ]]
    then
        gitBranch=""
    fi

    if [[ ! ${gitStatus} =~ "working directory clean" ]]
    then
        state="${RED}⚡"
    fi
    
    if ( echo "$gitStatus" | grep -q "ahead of" )
    then
        remote="${YELLOW}↑"
    fi

    if test -n "$remote" || test -n "$state"
    then
        echo " (${gitBranch}${remote}${state}${COLOR_NONE})"
    else
        echo " (${gitBranch}${GREEN}✇${COLOR_NONE})"
    fi
fi

