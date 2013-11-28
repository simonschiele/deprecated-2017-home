#!/bin/bash
hook_name=setup_repos
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_once=false
hook_version=0.1
hook_sudo=false
#hook_hostnames=""
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

#echo "Fixing home repo"
#sed -i -e 's|http.*://simon.psaux.de/git/|git@simon.psaux.de:|g' \
#/home/simon/.git/config

if ( ${success} )
then
    echo "> Checking repos"
    cd ~/
    cd "${OLDPWD}" 2>/dev/null
fi

if ( ${success} )
then
    echo "> Checking private repos"
    cd ~/

    if [ ! -d .bin-private/ ]
    then
        echo -e "> Checking out ~/.bin-private/"
        #git clone git@psaux.de:dot.bin-private.git .bin-private
    fi

    if [ ! -d .bin-private/ ]
    then
        echo -e "> Checking out ~/.bin-private/"
        #git clone git@psaux.de:dot.bin-ypsilon.git .bin-ypsilon
    fi

    if [ ! -d .fonts/ ] || [ ! -d .fonts/.git/ ]
    then
        if [ -d .fonts/ ]
        then
            echo -e "> Moving old .fonts folder -> ~/.fonts-backup/"
            mv .fonts .fonts-backup

            echo -e "> Checking out ~/.fonts/"
            #git clone git@psaux.de:dot.fonts.git .fonts/
        fi
    fi

    if [ ! -d .backgrounds/ ] || [ ! -d .backgrounds/.git/ ]
    then
        if [ -d .backgrounds/ ]
        then
            echo -e "> Moving old .backgrounds folder -> ~/.backgrounds-backup/"
            mv .backgrounds .backgrounds-backup

            echo -e "> Checking out ~/.backgrounds/"
            #git clone git@psaux.de:dot.backgrounds.git .backgrounds/
        fi
    fi

    cd "${OLDPWD}" 2>/dev/null
fi

