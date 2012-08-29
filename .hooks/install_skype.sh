#!/bin/bash
hook_name=install_skype
hook_systemtypes="workstation laptop"
hook_optional=false
hook_version=0.1

echo ">>> Generating '/etc/apt/sources.list.d/skype.list'"
echo -e "deb http://download.skype.com/linux/repos/debian/ testing non-free" > /etc/apt/sources.list.d/skype.list

echo ">>> Updating package lists"
apt-get update

echo ">>> Install package 'skype'"
apt-get install skype

