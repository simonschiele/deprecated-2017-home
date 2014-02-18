#!/bin/bash
hook_name=setup_sudo
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.3
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

sudoers="/etc/sudoers"

content="Defaults\t\tenv_reset\n"
content="${content}Defaults\t\tmail_badpass\n"
content="${content}Defaults\t\tinsults\n"
content="${content}Defaults\t\tenv_keep += HOME\n"
content="${content}Defaults\t\tsecure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\n"
content="${content}root\tALL=(ALL:ALL)\tALL\n"
content="${content}%sudo\tALL=(ALL:ALL)\tALL\n\n"
content="${content}#includedir /etc/sudoers.d\n"
echo -e "$content" | sudo tee /etc/sudoers >/dev/null

