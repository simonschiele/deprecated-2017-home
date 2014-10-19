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

if $( LANG=C git rev-parse --is-inside-work-tree 2>/dev/null ) ; then
    
    #gitStatus="LANG=C git diff --quiet --ignore-submodules HEAD"
    gitStatus="$( LANG=C git status 2>/dev/null )"
    gitBranch="$( LANG=C git symbolic-ref -q --short HEAD )"

    if [ "${gitBranch}" = 'master' ] ; then
        gitBranch=""
    fi

    if [[ ! ${gitStatus} =~ "working directory clean" ]] ; then
        state="$( color.ps1 red )⚡"
    fi

    if [[ "${gitStatus}" =~ "ahead of" ]] ; then
        ahead="$( color.ps1 yellow )↑"
    fi

    if test -n "${ahead}" || test -n "${state}" ; then
        echo "(${gitBranch}${ahead}${state}$( color.ps1 none ))"
    else
        echo "(${gitBranch}$( color.ps1 green )♥$( color.ps1 none ))"
    fi
fi

