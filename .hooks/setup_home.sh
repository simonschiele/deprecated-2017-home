#!/bin/bash
hook_name=setup_home
hook_systemtypes="minimal server workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

status=0

git submodule init
git submodule --recursive update

if [ -e .fonts/ ]
then
    mv .fonts .fonts-old
fi
git clone git@simon.psaux.de:fonts.git .fonts/

if [ -e .backgrounds/ ]
then
    mv .backgrounds .backgrounds-old
fi
git clone git@simon.psaux.de:backgrounds.git .backgrounds/


