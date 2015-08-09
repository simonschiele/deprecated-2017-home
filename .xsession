#!/bin/sh

# DOTFILE: ~/.xsession
# by Simon Schiele <simon.codingmonkey@googlemail.com>

# ghetto-rotate .xsession-errors 
cp -f ${HOME}/.xsession-errors ${HOME}/.xsession-errors.old 2>/dev/null >&2
echo "[`date`] starting .xsession" > ${HOME}/.xsession-errors

#########
# Input
#########

# Pass -ardelay 250 -arinterval 20 to X server instead.
#xset r on
#xset r rate 250 50

# kill keyring
#for process in polkit-gnome-authentication-agent-1 gnome-keyring-daemon
#do
    #if ( ps -C $process 2>/dev/null >&2 )
    #then
        #echo "killing running '$process'" >> $HOME/.xsession-errors
        #killall -9 $process 2>/dev/null >&2
    #fi
#done

# start polkit-gnome-authentication-agent + gnome-keyring-daemon
#/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
echo "starting + exporting gnome-keyring-daemon" >> ${HOME}/.xsession-errors
pkill -9 gnome-keyring-daemon 2>/dev/null
eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets )"
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET

# setting multihead at work
if test "$( hostname -s )" = "simon-work" ; then
    xrandr --output HDMI1 --left-of VGA1
fi

# launch awesome
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session awesome 2>>${HOME}/.xsession-errors >&2

# launch i3
exec dbus-launch --exit-with-session i3 2>>${HOME}/.xsession-errors >&2

echo "[`date`] .xsession done" >> ${HOME}/.xsession-errors

