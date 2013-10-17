#!/bin/bash
hook_name=skel
hook_systemtypes="minimal server workstation laptop"    # optional, default: empty
hook_optional=false                                     # optional, default: true
hook_version=0.1                                        # optional, default: 0.0
hook_once=true                                          # optional, default: true
hook_sudo=true                                          # optional, default: true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################
