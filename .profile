#!/bin/sh
#
# ~/.profile: Simons .profile
#
# This file will be executed by the command interpreter for login shells.
#
# It will just source the ~/.bashrc if it isn't loaded already and detects
# that it is running inside a BASH.
#

load_bashrc() {
    already_imported=false

    if test -n "$BASH_VERSION" && test -r "$HOME"/.bashrc ; then
        for src in "${BASH_SOURCE[@]}" ; do
            if [ "$src" = "$HOME/.bashrc" ] ; then
                already_imported=true
            fi
        done

        if ! $already_imported ; then
            . "$HOME"/.bashrc
        fi
    fi

    unset already_imported src
}

profile() {
    load_bashrc
}

profile "$@"
