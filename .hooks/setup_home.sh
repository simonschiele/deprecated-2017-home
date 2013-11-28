#!/bin/bash
hook_name=setup_home
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_once=false
hook_version=0.1
hook_sudo=true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( $success )
then
    echo "> setting up home"
fi

