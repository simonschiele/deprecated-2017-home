#!/bin/bash
#
# little helper script for hooks
#

if ( echo ${0} | grep -q "helper\.sh$" )
then
    echo "Don't call this helper directly."
    echo "Just source it in your hook script."
    exit 1
fi

if ! [ -e ~/.system.conf ]
then
    echo "[error] could not find '~/.system.conf'" >&2
    exit 1
fi

if [ $UID -ne 0 ]
then
    echo "[error] Please call with root/sudo permissions" >&2
    exit 1
fi

if [ -z "${hook_name}" ] || [ -z "${hook_version}" ] || [ -z "${hook_optional}" ]
then
    echo "[error] Please set at least \$hook_name, \$hook_version and \$hook_optional in your hook" >&2
    exit 1
fi

echo -e "\nLoading hook '${hook_name}'\n"

if ( grep -q "^${hook_name}@${hook_version}" ~/.system.conf ) 
then
    if ! ( echo "${@}" | grep -q "\-f" )
    then
        echo -e "Everything up-to-date.\n"
        exit 0
    else
        echo -e "Everything up-to-date but forced to continue.\n"
    fi
else
    echo -e "Update Available. Executing hook.\n"
fi

finished() {
    if ( grep -q "^${hook_name}@" ~/.system.conf )
    then 
        sed -i "s|^${hook_name}@.*$|${hook_name}@${hook_version}|g" ~/.system.conf
    else
        echo "${hook_name}@${hook_version}" >> ~/.system.conf 
    fi
    
    echo
    echo -e "Hook '${hook_name}' completed."
    echo
}

trap finished 0

