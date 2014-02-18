#!/bin/bash
hook_name=setup_share
hook_systemtypes="workstation laptop mediacenter"
hook_optional=false
hook_version=0.3
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

sudo mkdir -p /share/
sudo chmod 777 /share/

if ( ! grep -q -e "//192.168.5.102/share" -e "//cbase/share" -e "//cbase.cnet/share" /etc/fstab ) ; then
    echo "> Adding /share/ to fstab"
    echo -e "//cbase.cnet/share\t/share\tcifs\tdefaults,username=simon,password=SigiIstDoof\t0 0" | sudo tee -a /etc/fstab >/dev/null
fi

if ( fping -q cbase.cnet )
then
    echo "> Mounting /share/"
    sudo mount /share/
fi

