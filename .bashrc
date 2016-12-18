#!/bin/bash

function verify_bash() {
    # test if shell is bash
    if [[ -z "$PS1" ]] || [[ -z "$BASH_VERSION" ]] ; then
        echo "ERROR: shell is not BASH" >&2
        return 1
    fi

    # test if file already included
    if [[ -n "$workflow_processed_bashrc" ]] ; then
        return
    fi

    # test if interactive
    if [[ "$-" != *i* ]] ; then
        return
    fi

    return 0
}

function verify_profile() {
    if [[ -z "$workflow_directories" ]] && [[ -f $HOME/.profile ]] ; then
        . "$HOME"/.profile
    fi
}

function bashrc() {
    local status=0

    verify_bash || return $?
    workflow_processed_bashrc=true

    verify_profile || status=$(( status + 1 ))

    workflow_includes=".bashrc.d bashrc.d"
    for dir in $workflow_directories ; do
        for inc in $workflow_includes ; do
            workflow_include_directory "$dir/$inc"
        done 
    done

    unset -f verify_bash setup_colors setup_completion setup_history \
             setup_includes setup_path setup_ssh setup_x11 \
             setup_applications bashrc

    return $status
}

bashrc "$@" || return $?
