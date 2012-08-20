#!/bin/bash
hook_name=hook-loader
hook_systemtypes=""
hook_optional=true
hook_version=0.1

echo



if [ ! -e "$@" ]
then
    echo "[error] loader script could not find '${@}'" >&2
    exit 1
fi

if [ ! -e ~/.system.conf ]
then
    echo "[error] could not find '~/.system.conf'" >&2
    exit 1
fi

eval $( grep "^hook_.*=" "${@}" )
echo "Loading hook '${hook_name}'"

if [ $UID -ne 0 ]
then
    echo "[error] Please call with root/sudo permissions" >&2
    exit 1
fi

if ( grep -q "^${hook_name}@${hook_version}" ~/.system.conf )
then
    echo "Everything up-to-date."
    exit 0
else
    echo "Update Available. Executing hook."
fi

source "${@}"

if ( grep -q "^${hook_name}@" ~/.system.conf )
then 
    sed -i "s|^${hook_name}@.*$|${hook_name}@${hook_version}|g" ~/.system.conf
else
    echo "${hook_name}@${hook_version}" >> ~/.system.conf 
fi

echo -e "Hook '${hook_name}' completed."

