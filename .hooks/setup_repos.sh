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
real_home=$( getent passwd ${SUDO_USER:-${USER}} | cut -d':' -f6 )

if [[ "${real_home}" == "/root" ]]
then
    echo "> ERROR: will not do anything in /root"
    success=false
fi

if ( ${success} )
then
    echo "> Checking private repos"
    cd ${real_home}

    if [ ! -e .bin-private/.git ]
    then
        echo -e "> Checking out ~/.bin-private/"
        if ! ( git clone git@psaux.de:dot.bin-private.git .bin-private )
        then
            echo "> WARNING: Checkout for ~/.bin-private/ failed"
            success=false
        fi
    fi

    if [ ! -e .bin-ypsilon/.git ]
    then
        echo -e "> Checking out ~/.bin-ypsilon/"
        if ! ( git clone git@psaux.de:dot.bin-ypsilon.git .bin-ypsilon )
        then
            echo "> WARNING: Checkout for ~/.bin-ypsilon/ failed"
            success=false
        fi
    fi

    if [ ! -e .fonts/.git ]
    then
        cont=true
        if [[ -e .fonts ]]
        then
            echo -e "> Moving old .fonts folder -> ~/.fonts-backup/"
            if ! ( mv -f .fonts .fonts-backup )
            then
                echo "> ERROR: couldn't move .fonts folder. will not overwrite old dir."
                success=false
                cont=false
            fi
        fi
        
        if ( ${cont} )
        then
            echo -e "> Checking out ~/.fonts/"
            if ! ( git clone git@psaux.de:dot.fonts.git .fonts/ )
            then
                echo "> WARNING: Checkout for ~/.fonts/ failed"
                success=false
            fi
        fi
    fi

    if [ ! -e .backgrounds/.git ]
    then
        cont=true
        if [[ -e .backgrounds ]]
        then
            echo -e "> Moving old .backgrounds folder -> ~/.backgrounds-backup/"
            if ! ( mv -f .backgrounds .backgrounds-backup )
            then
                echo "> ERROR: couldn't move .backgrounds/ folder. will not overwrite old dir."
                success=false
                cont=false
            fi
        fi

        if ( ${cont} )
        then
            echo -e "> Checking out ~/.fonts/"
            if ! ( git clone git@psaux.de:dot.backgrounds.git .backgrounds/ )
            then
                echo "> WARNING: Checkout for ~/.backgrounds/ failed"
                success=false
            fi
        fi
    fi

    echo "> Overwriting pull with push repos"
    find -type f -name "config" | while read file
    do
        if ( grep -q -i -e "url\ =.*http.*simonschiele" -e "url\ =.*http.*psaux.de" "$file" )
        then
            echo "> Fixing $file"
            sed -i -e 's|http.*simon\.psaux\.de/git/|git@simon.psaux.de:|g' -e 's|http.*github.com/simonschiele/|git@simon.psaux.de:|g' "$file"
        fi
    done
    
    cd "${OLDPWD}" 2>/dev/null
fi

