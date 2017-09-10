#!/bin/bash
#
# ~/.bashrc: Simons main .bashrc
#
# This file mostly builds my $PATH and is used as a loader for further configs.
#
# It will check a bunch of directories (listed in $check_directories) for
# .bin/, bin/ or BIN/ directories and adds these to the path if available.
#
# The same directories (listed in $check_directories) will be checked
# afterwards for .bashrc and bashrc files and files in bashrc.d/ and
# .bashrc.d/ subdirectories. These will be all sourced one after another.
#
# If you are interested in my real bash config, please refer to the
# reposioties README[1] or have a look around in .bashrc.d/[2].
#
# [1] https://github.com/simonschiele/home/tree/master/.repo/README.md
# [2] https://github.com/simonschiele/home/tree/master/.bashrc.d
#


function debug() {
    if [[ -n "$DEBUG" ]] ; then
        echo "| $1" | tee -a "$HOME"/DEBUG.log >&2
    fi
}

function verify_bash() {
    # test if shell is bash
    if [[ -z "$PS1" ]] || [[ -z "$BASH_VERSION" ]] ; then
        echo "ERROR: shell is not BASH" >&2
        return 1
    fi

    # test if interactive
    if [[ "$-" != *i* ]] ; then
        return 1
    fi

    return 0
}

function already_sourced() {
    # test if "$1" was already loaded

    local src

    for src in "${BASH_SOURCE[@]}" ; do
        [[ "$src" == "$1" ]] && return 0
    done

    return 1
}

function include_once() {
    if already_sourced "$1" ; then
        return 1
    fi

    if [[ -r "$1" ]] ; then
        debug "SOURCE $1"
        if ! source "$1" ; then
            return 1
        fi
    fi
    return 0
}

function bashrc() {
    local i file

    # All entries in 'check_directories' will get checked for a bin/ or .bin/
    # directory. If one is found, it gets added to $PATH.
    local check_directories=( . .local .vim .config/i3 .private .work )

    # These 'add_directories' get added to $PATH directly if they exist.
    # I use this mostly for small scripts that have their own repo.
    local add_directories=( .bin/vils-ng )

    verify_bash || return 1
    include_once "$HOME"/.profile

    # build $PATH
    for dir in ${check_directories[*]} ; do
        for i in {.,}bin BIN ; do
            if [[ -d "$HOME/$dir"/"$i" ]] ; then
               debug "PATH $HOME/$dir/$i"
               PATH="$HOME/$dir/$i:$PATH"
            fi
        done
    done

    # include .bashrc, bashrc, bashrc.d/*
    for dir in ${check_directories[*]} ; do
        for i in {.,}bashrc {.,}bashrc.d ; do
            for file in "$dir"/"$i"{,/*} ; do
                # skip if file is a directory or exactly this bashrc
                if [[ "$file" == "./.bashrc" ]] || [[ -d "$file" ]] ; then
                    continue
                fi
                include_once "$file"
            done
        done
    done
}

bashrc "$@"
