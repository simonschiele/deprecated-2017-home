#!/bin/sh

date > $HOME/.xsession-errors

eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets )"
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET

awesome >> $HOME/.xsession-errors 2>> $HOME/.xsession-errors

killall -9 gnome-keyring-daemon 2>&1 >/dev/null

