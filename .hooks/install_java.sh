#!/bin/bash
hook_name=install_java
hook_version=0.2
hook_systemtypes="minimal workstation laptop"           # optional, default: empty
hook_optional=true                                      # optional, default: true
hook_once=true                                          # optional, default: true
hook_sudo=true                                          # optional, default: true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ( readlink -f /usr/bin/java | grep -i -q -e "openjdk" -e "open-jdk" )
then
    echo "> WARNING: java not linked against openjdk. doing nothing."
else
    jdk_path=/share/Software/java4debs/jdk-7u51-linux-i586.tar.gz

    echo "> Installing 'java-package'"
    if ! ( sudo apt-get install java-package )
    then
        echo "> ERROR: Could't install java-package"
        success=false
    fi

    if ( $success ) && [[ ! -e ${jdk_path} ]]
    then
        echo "> ERROR: '${jdk_path}' not found. Please run again, when connected to home-network."
        success=false
    fi

    sudo rm -rf /tmp/build-java/ 2>/dev/null || success=false
    mkdir -p /tmp/build-java/ || success=false

    if ( $success )
    then
        cd /tmp/build-java/

        echo "> Building debian package. This can take a while."

        if ( make-jpkg $jdk_path )
        then
            echo "> Debian packages build"
        else
            echo "> ERROR: Could not build deb packages"
            success=false
        fi

        cd $OLDPWD
    fi

    if ( $success )
    then
        cd /tmp/build-java/

        echo "> Installing debian package"

        if ( sudo dpkg -i oracle*java*.deb )
        then
            echo "> Installed successfully"
        else
            echo "> ERROR: Could not install deb package"
            success=false
        fi

        cd $OLDPWD
    fi

    if ( $success )
    then
        echo "> Setting alternatives"
        sudo update-alternatives --config java || success=false
        sudo update-alternatives --config javac || success=false
        sudo update-alternatives --config javaws || success=false
        sudo update-alternatives --config javadoc || success=false
        sudo update-alternatives --config jconsole || success=false
        sudo update-alternatives --config jdb || success=false

        if ( ! $success )
        then
            echo "> ERROR: error while setting alternatives"
            success=false
        fi
    fi

    if ! ( sudo rm -rf /tmp/build-java/ 2>/dev/null )
    then
        echo "> WARNING: couldn't remove '/tmp/build-java/'"
    fi
fi

