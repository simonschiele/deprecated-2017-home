#!/bin/bash
hook_name=setup_module_blacklist
hook_systemtypes="minimal workstation laptop"
hook_optional=true
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( ! grep -q /etc/modprobe.d/custom-blacklist.conf ) 
then
    echo "blacklist pcspkr" >> /etc/modprobe.d/custom-blacklist.conf
fi

#cd $OLDPWD

