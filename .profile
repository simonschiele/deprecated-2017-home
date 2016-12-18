#!/bin/sh
#
# ~/.profile: executed by the command interpreter for login shells.
#
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
#
# Additionally to loading different things, this .profile-file sets my $PATH
# and is therefore an elementary part of my workflow scripts.
#
# Please use posix-sh for this script and the complementary scripts
# in ~/.profile.d/*.sh
#
# by Simon Schiele <simon.codingmonkey@gmail.com>
#
# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

workflow_add_path() {
    # adds a directory to $PATH, if exists and isn't included yet.
    new_path="$1"

    if ! test -d "$new_path" ; then
        return 1
    elif ( echo "$PATH" | sed 's/:/\n/g' | grep -q "^$1$" ) ; then
        return 1
    fi

    PATH="$new_path:$PATH"

    return 0
}

workflow_find_bin_directories() {
    dir=`readlink -f "$1"`

    if ! test -d "$dir" ; then
        return 1
    fi

    find "$dir" -maxdepth 1 \
                -type d -iname ".bin" -or \
                -type d -iname "bin" \
                        | sed 's/^\.\///g'
}

workflow_include_directory() {
    dir=`readlink -f "$1"`
    if ! test -d "$dir" ; then
        return
    fi

    for file in "$dir"/* ; do
        if test -f "$file" && test -r "$file" ; then
            . "$file" || echo "Error loading: $file" >&2
        fi
    done
}

if test -n "$workflow_processed_profile" ; then
    return
else
    workflow_processed_profile=true
fi

# settings
workflow_directories=". .private .work .config/i3"
workflow_includes=".profile.d profile.d"

# setup $PATH
for dir in $workflow_directories ; do
    for bin in `workflow_find_bin_directories "$dir"` ; do
        workflow_add_path "$bin"
    done
done
workflow_add_path "$HOME/.lib/vils-ng"

# load includes
for dir in $workflow_directories ; do
    for inc in $workflow_includes ; do
        workflow_include_directory "$dir/$inc"
    done
done

# load .bashrc
if [ -n "$BASH_VERSION" ] ; then
    if [ -f "$HOME"/.bashrc ]; then
        . "$HOME"/.bashrc
    fi
fi
