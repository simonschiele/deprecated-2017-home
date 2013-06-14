#!/bin/bash
hook_name=install_skype
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

#echo ">>> Generating '/etc/apt/sources.list.d/skype.list'"
#echo -e "deb http://download.skype.com/linux/repos/debian/ testing non-free" > /etc/apt/sources.list.d/skype.list

#echo ">>> Updating package lists"
#apt-get update

#echo ">>> Install package 'skype'"
#apt-get install skype

wget -O skype-install.deb http://www.skype.com/go/getskype-linux-deb
dpkg -i skype-install.deb

