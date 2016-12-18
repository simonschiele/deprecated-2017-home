#!/bin/bash
grep "$@" \
    ~/.bash* \
    ~/.profile* \
    ~/.xsession \
    ~/.bin/ \
    ~/.private/bin/ \
    ~/.private/bash* \
    ~/.private/*/bin/ \
    ~/.private/*/bash* \
    -R
