#!/bin/bash
hook_name=setup_vim
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.1

if ! [ -d ~/.vim/ ] || ! [ -e ~/.vim/.git ]
then
    echo "vim config not checked out properly"
fi

if [ -n "$( which rake )" ]
then
    echo "Setting up Command-T"
    cd ~/.vim/plugins/command-t/
    rake make
    echo
    cd $OLDPWD
else
    echo "Skipping Command-T setup: rake not available"
fi

