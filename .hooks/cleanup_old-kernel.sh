#!/bin/bash
hook_name=cleanup_old-kernel
hook_systemtypes="minimal server workstation laptop"
hook_optional=true
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || exit 3 
###########################################################

apt-get remove $(dpkg -l|awk '/^ii linux-image-/{print $2}'|sed 's/linux-image-//'|awk -v v=`uname -r` 'v>$0'|sed 's/-generic*//'|awk '{printf("linux-headers-%s\nlinux-headers-%s-generic*\nlinux-image-%s-generic*\n",$0,$0,$0)}')

