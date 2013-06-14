#!/bin/bash
hook_name=setup_apt
hook_systemtypes="minimal server workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ! ( grep -h -v "^[ ]*#" /etc/apt/ -R | grep -q -i "cache-limit" )
then
    echo -e "Apt::Cache-Limit \"16384000\";">> /etc/apt/apt.conf
fi

