#!/bin/bash
hook_name=install_google-chrome
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.2
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

echo ">>> Generating '/etc/apt/sources.list.d/google-chrome.list'"
echo -e "### THIS FILE IS AUTOMATICALLY CONFIGURED ###\n# You may comment out this entry, but any other modifications may be lost.\ndeb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

echo ">>> Updating package lists"
apt-get update

echo ">>> Install package 'google-chrome-stable'"
apt-get --purge remove google-chrome-stable google-chrome-beta

echo ">>> Install package 'google-chrome-unstable'"
apt-get install google-chrome-unstable

