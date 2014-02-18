#!/bin/bash
hook_name=testhook2
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.1
hook_once=true
hook_sudo=false
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( ${success} )
then
    echo "bla bla bla bla"
    echo "bla bla bla bla"
    echo "bla bla bla bla"
    echo "bla bla bla bla"
    echo "bla bla bla bla"
fi

