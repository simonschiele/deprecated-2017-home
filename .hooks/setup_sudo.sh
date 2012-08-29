#!/bin/bash
hook_name=setup_sudo
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || exit 3 
###########################################################

sudoers="/etc/sudoers"
echo -e "Defaults\t\tenv_reset" > "${sudoers}"
echo -e "Defaults\t\tmail_badpass" >> "${sudoers}"
echo -e "Defaults\t\tenv_keep += HOME" >> "${sudoers}"
echo -e "Defaults\t\tsecure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"" >> "${sudoers}"
echo -e "" >> "${sudoers}"
echo -e "root\tALL=(ALL:ALL)\tALL\n" >> "${sudoers}"
echo -e "%sudo\tALL=(ALL:ALL)\tALL\n" >> "${sudoers}"
echo -e "" >> "${sudoers}"
echo -e "#includedir /etc/sudoers.d" >> "${sudoers}"

