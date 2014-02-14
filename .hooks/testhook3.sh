#!/bin/bash
hook_name=testhook3
hook_systemtypes="server"
hook_optional=false
hook_version=0.3
hook_once=false
hook_sudo=false
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( ${success} )
then
    echo "> blub blub blub blub"
    echo "> blub blub blub blub"
    echo "> blub blub blub blub"
    echo "> blub blub blub blub"
    echo "> blub blub blub blub"
fi

