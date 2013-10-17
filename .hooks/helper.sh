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

if [ -z "${hook_name}" ] || [ -z "${hook_version}" ] || [ -z "${hook_optional}" ]
then
    echo "[error] Please set at least \$hook_name, \$hook_version and \$hook_optional in your hook" >&2
    exit 1
fi

echo -e "\nRunning hook: ${hook_name} ${hook_version+(${hook_version})}"

if [ -z "${hook_sudo}" ] || ( ${hook_sudo} )
then
    if [ $UID -ne 0 ]
    then
        echo "[error] Please call with root/sudo permissions" >&2
        exit 1
    fi
fi

echo -e "\nLoading hook '${hook_name}'\n"


if ! ( ${hook_once} )
then
    #echo -e "Executing hook.\n"
    echo -n
elif ( grep -q "^${hook_name}@${hook_version}" ~/.system.conf )
then
    if ! ( echo "${@}" | grep -q "\-f" )
    then
        echo -e "Everything up-to-date.\n"
        exit 0
    else
        echo -e "Everything up-to-date but forced to continue. Executing hook.\n"
    fi
else
    echo -e "Update Available. Executing hook.\n"
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

