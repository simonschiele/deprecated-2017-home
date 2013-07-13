#!/bin/bash
hook_name=setup_vim
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.4
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

status=0

cd ~/.vim/
git submodule init
git submodule update --recursive
cd $OLDPWD

if ! [ -d ~/.vim/ ] || ! [ -e ~/.vim/.git ]
then
    echo "vim config not checked out properly"
    status=1
fi

#echo "Setting up Command-T"
#cd ~/.vim/plugins/command-t/ruby/command-t
#ruby extconf.rb
#make
#cd $OLDPWD

echo "Setting up vimproc"
cd ~/.vim/plugins/vimproc/
make -f make_unix.mak
cd $OLDPWD

