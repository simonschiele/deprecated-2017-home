#!/bin/bash
hook_name=skel
hook_version=0.1
hook_systemtypes="minimal server workstation laptop"    # optional, default: empty
hook_optional=false                                     # optional, default: true
hook_once=true                                          # optional, default: true
hook_sudo=true                                          # optional, default: true
hook_hostnames="cstation cpad simon-work"               # optional, default: ""
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################
