#!/bin/bash
hook_name=setup_vim
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_once=false
hook_version=0.4
hook_sudo=false
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( ${success} )
then
    if ! [ -d .vim/ ] || ! [ -e .vim/.git ]
    then
        echo "> vim config not checked out properly. canceling."
        success=false
    fi
fi

if ( ${success} )
then
    echo "> Checking for submodules"
    cd .vim/

    if [ ! -e plugins/vim-pathogen/autoload/pathogen.vim ]
    then
        echo "> No submodules found. Checking out."
        git submodule init || success=1
        git submodule update --recursive || success=1
    fi

    cd "${OLDPWD}" 2>/dev/null
fi

if ( ${success} )
then
    echo "> Checking submodules for updates"
    cd .vim/plugins/

    echo -e "\t* Update in powerline-fonts"
    echo -e "\t* Update in lib/git-prompt"

    cd "${OLDPWD}" 2>/dev/null
fi

if ( ${success} )
then
    echo "> Checking vimproc"
    cd ~/.vim/plugins/vimproc/

    if [ ! -e autoload/vimproc_unix.so ]
    then
        echo "> No binary found. Setting up vimproc."
        make -f make_unix.mak
    fi

    cd "${OLDPWD}" 2>/dev/null
fi

