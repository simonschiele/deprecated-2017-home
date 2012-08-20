#!/bin/sh

date > $HOME/.xsession-errors

/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &

killall -9 gnome-keyring-daemon 2>/dev/null
eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets )"
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET

dbus-launch --exit-with-session awesome >> $HOME/.xsession-errors 2>> $HOME/.xsession-errors

killall -9 gnome-keyring-daemon 2>/dev/null

