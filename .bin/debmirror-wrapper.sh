#!/bin/bash
 
# sourcehost
HOST=ftp.de.debian.org;
 
# destination directory
DEST=/mnt/bigdisk2/debmirror/debian
 
# Debian version(s) to mirror
DIST=testing
 
# architecture
ARCH=i386
 
#--section=main,contrib,non-free,main/debian-installer \
debmirror ${DEST} \
    --nosource \
    --host=${HOST} \
    --root=/debian \
    --dist=${DIST} \
    --section=main \
    --arch=${ARCH} \
    --passive --cleanup \
    --state-cache-days=7 \
    --progress --verbose
