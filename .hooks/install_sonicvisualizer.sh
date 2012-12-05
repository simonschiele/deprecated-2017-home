#!/bin/bash
hook_name=install_sonicvisualizer
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh
###########################################################

URL="http://www.sonicvisualiser.org/download.html"

package=$( wget -q -O- "${URL}" | grep_urls | grep -e "i386" )
packagename=$( basename "$package" )

wget -q "$package"
sudo dpkg -i "$packagename"

