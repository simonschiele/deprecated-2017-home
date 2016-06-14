#!/bin/sh
#
# ~/.profile
#
# please use posix-sh for this script and the complementary scripts
# in ~/.profile.d/*.sh
#

echo "[running] ~/.profile" >&2

for config in "$HOME"/.profile.d/*.sh ; do
    [ -r "$config" ] && . "$config"
done
unset -v config

# if iteractive + login -> chainload ~/.bashrc
if [ -n "$BASH_VERSION" ]; then
    # 'shopt + [[ ]] are not posix'
    # shellcheck disable=SC2039
    if [ -f "$HOME"/.bashrc ] && shopt -q login_shell && [[ "$-" == *i* ]] ; then
        . "$HOME"/.bashrc
    fi
fi
