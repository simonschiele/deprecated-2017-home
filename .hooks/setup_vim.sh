#!/bin/bash
hook_name=setup_vim
hook_systemtypes="minimal server workstation laptop"
hook_optional=true
hook_version=0.2
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

cd ~/vim/
git submodule init
git submodule update
cd $OLDPWD

if ! [ -d ~/.vim/ ] || ! [ -e ~/.vim/.git ]
then
    echo "vim config not checked out properly"
fi

echo "Setting up Command-T"
cd ~/.vim/plugins/command-t/ruby/command-t
ruby extconf.rb
make
cd $OLDPWD

