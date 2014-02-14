#!/bin/bash
hook_name=install_minecraft
hook_version=0.2
hook_systemtypes="minimal workstation laptop"    # optional, default: empty
hook_optional=false                                      # optional, default: true
hook_once=true                                          # optional, default: true
hook_sudo=true                                          # optional, default: true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( readlink -f /usr/bin/java | grep -i -q -e "openjdk" -e "open-jdk" )
then
    echo "WARNING: java is linked to openjdk. Please install oracle java to play the game."
fi

jar_path=/share/Software/Games/Minecraft.jar
target_path=/opt/minecraft

if [[ -e ${jar_path} ]]
then
    if [[ ! -d ${target_path} ]]
    then
        sudo mkdir -p ${target_path}
    fi

    if ( sudo cp -f ${jar_path} ${target_path} )
    then
        echo "> gamefile copied"
    else
        echo "ERROR: Couldn't copy ${jar_path} -> ${target_path}"
        success=false
    fi

    if [[ ! -e ~/.bin/minecraft ]]
    then
        echo "WARNING: ~/.bin/minecraft not found. home-dir checked out properly?"
    fi
else
    echo "ERROR: '${jar_path}' not found. Please run again, when connected to home-network."
    success=false
fi

