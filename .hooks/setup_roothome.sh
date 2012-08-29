#!/bin/bash
hook_name=setup_roothome
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || exit 3 
###########################################################

SRC=/home/${SUDO_USER:-$USER}

if [ ! -d ${SRC} ]
then
    echo "Could not find source dir '${SRC}'"
    exit 1
fi

cd /root/

rm -rf .config/ .cache/ Desktop/ .gconf* .gnome* .gstream* .gvfs .pulse* .thumb* .Virtual* .vim* .bashrc .profile .gitconfig 2>/dev/null
rm -rf Desktop/ Downloads/ Virtual* 2>/dev/null

ln -s ${SRC}/.gitconfig .
ln -s ${SRC}/.bashrc .
ln -s ${SRC}/.profile .

ln -s ${SRC}/.vim/ .
ln -s .vim/vimrc .vimrc


cd $OLDPWD

