#!/bin/bash
hook_name=skel
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.1
hook_once=true
hook_sudo=true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################
