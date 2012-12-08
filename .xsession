#!/bin/sh

echo "[date] starting xorg" > $HOME/.xsession-errors

for process in polkit-gnome-authentication-agent-1 gnome-keyring-daemon
do
    if ( ps -C $process 2>/dev/null >&2 )
    then
        echo "killing running '$process'" >> $HOME/.xsession-errors
        killall -9 $process 2>/dev/null >&2
    fi
done

/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets )"
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET

#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session awesome 2>>${HOME}/.xsession-errors >&2
exec dbus-launch --exit-with-session awesome 2>>${HOME}/.xsession-errors >&2

