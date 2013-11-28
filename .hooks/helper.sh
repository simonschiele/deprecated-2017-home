#!/bin/bash
#
# little helper script for hooks
#

hr="#################################################"
conffile=~/.system.conf
verbose=${verbose:-false}
cancel=${cancel:-false}
success=true

if ( echo ${0} | grep -q "helper\.sh$" )
then
    echo -e "\nDon't call this helper directly." >&2
    echo -e "Just source it in your hook script." >&2
    echo -e "For an example, have a look at the skel.sh hook.\n" >&2
    success=false
    cancel=true
    exit 1
fi

if ! [ -e ${conffile} ]
then
    echo -e "\nCouldn't find ${conffile}. Creating an empty one for you.\nPlease configure at least the systemtype in ${conffile}\n"
    echo -e "hostname=\"\"\ndomain=\"\"\nsystemtype=\"\"\nusername=\"\"\n${hr}" > ${conffile}
    success=false
    cancel=true
else
    declare $( grep -v '^#' ${conffile} | grep -o '.*=.*' )
fi

if ! ( echo "${@}" | grep -q "\-v" )
then
    verbose=true
fi

if ( ${success} )
then

    echo -e "Running hook: ${hook_name:-Unknown} ${hook_version+(${hook_version:-Unknown Version})}"

    if [ -z "${systemtype}" ]
    then
        echo "[error] Please set at least the systemtype in ${conffile}" >&2
        success=false
    fi

    if [ -z "${hook_name}" ] || [ -z "${hook_version}" ]
    then
        echo "[error] Please set at least \$hook_name and \$hook_version in $( basename ${0})" >&2
        success=false
    fi

    if [ -z "${hook_sudo}" ] || ( ${hook_sudo} )
    then
        if [ $UID -ne 0 ]
        then
            if ! ( sudo -n echo -n 2>/dev/null )
            then
                echo "> This hook needs sudo permissions"
                echo -n "> "
                if ! ( sudo echo -n )
                then
                    echo "> [error] Authentication not possible" >&2
                    success=false
                fi
            fi
        fi
    fi
fi

if ( ${success} )
then
    if ! ( ${hook_once} )
    then
        echo -n
    elif ( grep -q "^${hook_name}@${hook_version}" ${conffile} )
    then
        if ! ( echo "${@}" | grep -q "\-f" )
        then
            echo -e "Hook '${hook_name}' up-to-date."
            exit 0
        else
            echo -e "Everything up-to-date but forced to continue. Executing hook."
        fi
    else
        echo -e "Update Available. Executing hook."
    fi
fi

get_setting() {
    # $1 setting
    # $2 [section]
    echo -n
}

set_setting() {
    # $1 config file
    # $2 setting
    # $3 [section]
    echo -n
}

finished() {

    if ( ${cancel} )
    then
        success=false
    fi

    if ( ${success} )
    then
        if ( grep -q "^${hook_name:-}@" ${conffile} )
        then
            sed -i "s|^${hook_name}@.*$|${hook_name}@${hook_version}|g" ${conffile}
        else
            echo "${hook_name}@${hook_version}" >> ${conffile}
        fi

        echo -e "Hook '${hook_name:-Unknown}' completed successfully."
    else
        ${cancel} || echo -e "Hook '${hook_name:-Unknown}' could NOT be processed successfully."
    fi

    #unset hook_name hook_version hook_systemtypes hook_optional hook_once hook_sudo hook_hostnames

    ${cancel} && exit 2
    ${success} ; exit $?
}
trap finished EXIT

