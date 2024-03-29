#!/bin/bash --login

export XSESSION_ERRORS="$HOME"/.xsession-errors

function log() {
    local msg=$1
    echo "[$( date )] $msg" >> "$XSESSION_ERRORS"
}

function log_rotate() {
    log " > rotating logfile"
    gzip -c "$XSESSION_ERRORS" >> "$XSESSION_ERRORS".old
    rm -f "$XSESSION_ERRORS" 2>/dev/null
    log " > logfile created"
}

function main() {
    log_rotate
    log " > starting xsession"

    log " > merging $HOME/.Xresources"
    xrdb -merge ~/.Xresources

    #### replace this with systemd!
    # start polkit-gnome-authentication-agent + gnome-keyring-daemon
    #/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
    log " > starting gnome-keyring"
    pkill -9 gnome-keyring-daemon 2>/dev/null
    eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets,gpg )"
    export GNOME_KEYRING_PID
    export GNOME_KEYRING_SOCKET

    log " > setting fixes for java in i3/awesome/..."
    export DE=generic
    export AWT_TOOLKIT=XToolkit
    export _JAVA_AWT_WM_NONREPARENTING=1

    log " > disabling dpms screen blank thingi"
    xset -dpms
    xset s off

    log " > disabling bell"
    xset -b

    # log " > enable zapping (C-A-<Bksp> kills X)"
    #setxkbmap -option terminate:ctrl_alt_bksp

    log " > checking for screenlayout"
    if [[ -x "$HOME/.screenlayout/$( hostname -s ).sh" ]] ; then
        log " > run screenlayout for $( hostname -s )"
        "$HOME/.screenlayout/$( hostname -s ).sh" || log ""
    else
        log " > no screenlayout - looking for failover"
        if grep -iq work /etc/hostname ; then
            log " > using 'work' xrandr failover"
            xrandr --output VGA-1 --mode 1680x1050 --pos 0x388 --rotate normal \
                   --output DP-1 --primary --mode 1920x1200 --pos 1680x238 --rotate normal \
                   --output DP-2 --mode 1920x1200 --pos 3600x0 --rotate right \
                   --output HDMI-2 --off --output HDMI-1 --off
        fi
    fi

    # todo: fix this construct (check modern way to launch
    #       window manager (maybe systemd?) and remove break
    #       to iterate again after wm broke down
    log " > starting window manager via dbus-launch"
    local window_managers="i3 awesome fluxbox gnome-session-classic"
    for wm in $window_managers ; do
        log " > trying to start window manager: $wm"
        dbus-launch --sh-syntax \
                    --exit-with-session \
                    "$wm" 2>> "$XSESSION_ERRORS" >&2
        break
    done

    if [ -e "$HOME"/.bash_logout ] ; then
        log " > executing $HOME/.bash_logout"
        . "$HOME"/.bash_logout
    fi

    log " > finished running xsession"
}

main "$@"
