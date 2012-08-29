#!/bin/bash
hook_name=setup_share
hook_systemtypes="minimal server workstation laptop"
hook_optional=true
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || exit 3 
###########################################################

if [ ! -d /share/ ]
then
    mkdir /share/
fi

if (!( grep -q "//192.168.5.102/share" /etc/fstab ) && !( grep -q "//cbase/share" /etc/fstab ))
then
    echo -e "//192.168.5.102/share\t/share\tcifs\tdefault,username=simon,password=SigiIstDoof\t0 0" >> ${BOOTSTRAP_MOUNT}/etc/fstab
fi

if ( fping -q 192.168.5.102 )
then
    mount /share/
fi

