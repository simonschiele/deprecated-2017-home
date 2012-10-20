#!/bin/bash
hook_name=install_spacefm
hook_systemtypes="workstation laptop"
hook_optional=true
hook_version=0.1
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh
###########################################################

cd ${HOME}/
mkdir build-spacefm/
cd build-spacefm/

git clone https://github.com/IgnorantGuru/spacefm.git
cd spacefm/

sudo apt-get install autotools-dev bash build-essential dbus desktop-file-utils libc6 libcairo2 libdbus-1-3 libglib2.0-0 libgtk2.0-0 libgtk2.0-bin libpango1.0-0 libstartup-notification0 libx11-6 shared-mime-info intltool pkg-config libgtk2.0-dev libglib2.0-dev fakeroot libstartup-notification0-dev libdbus-1-dev libgdk-pixbuf2.0-0 libudev0 libudev-dev

./configure
make
sudo make install

