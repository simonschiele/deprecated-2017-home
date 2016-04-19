#!/bin/bash --login

export XSESSION_ERRORS="$HOME"/.xsession-errors

function log_rotate() {
    log "logfile rotated"
    cat "$XSESSION_ERRORS" >> "$XSESSION_ERRORS".old
    rm -f "$XSESSION_ERRORS"

    log "logfile created"
}
  
function log() {
    local msg=$1
    echo "[$( date )] $msg" >> "$XSESSION_ERRORS"
}

function main() {
    log_rotate
    log "starting xsession"

    log "merging $HOME/.Xresources"
    xrdb -merge ~/.Xresources

    #### replace this with systemd
    # start polkit-gnome-authentication-agent + gnome-keyring-daemon
    #/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
    log "starting gnome-keyring"
    pkill -9 gnome-keyring-daemon 2>/dev/null
    eval "$( gnome-keyring-daemon --start --components=keyring,pkcs11,ssh,secrets,gpg )"
    export GNOME_KEYRING_PID
    export GNOME_KEYRING_SOCKET

    # java fixes for awesome/i3
    export DE=generic
    export AWT_TOOLKIT=XToolkit
    export _JAVA_AWT_WM_NONREPARENTING=1

    # Disable DPMS turning off the screen
    xset -dpms
    xset s off

    # Disable bell
    xset -b

    # Enable zapping (C-A-<Bksp> kills X)
    #setxkbmap -option terminate:ctrl_alt_bksp

    # start window manager
    local window_managers="i3 awesome fluxbox gnome-session-classic"
    for wm in $window_managers ; do
        log "trying to start window manager: $wm"
        dbus-launch --sh-syntax \
                    --exit-with-session \
                    "$wm" 2>> "$XSESSION_ERRORS" >&2
        break
    done

    # source bash_logout for cleanup purposes
    if [ -e "$HOME"/.bash_logout ] ; then
        log "executing $HOME/.bash_logout"
        . "$HOME"/.bash_logout
    fi

    log "finished running xsession"
}

main "$@"
