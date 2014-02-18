#!/bin/bash
hook_name=install_google-chrome
hook_systemtypes="workstation laptop"
hook_optional=false
hook_version=0.4
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

echo ">>> Generating '/etc/apt/sources.list.d/google-chrome.list'"
echo -e "### THIS FILE IS AUTOMATICALLY CONFIGURED ###\n# You may comment out this entry, but any other modifications may be lost.\ndeb http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

echo ">>> Updating package lists"
sudo apt-get update

echo ">>> Install package 'google-chrome-stable'"
sudo apt-get --purge remove google-chrome-stable google-chrome-beta

echo ">>> Install package 'google-chrome-unstable'"
sudo apt-get install google-chrome-unstable

