#!/bin/bash

# if shell is a login shell, clean the screen on logout
if [ "$SHLVL" == 1 ] ; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

