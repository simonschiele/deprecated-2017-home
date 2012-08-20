#!/bin/bash

### !!! CONFIG !!! ###
BOOTSTRAP_HOSTNAME="test.cnet.loc"
BOOTSTRAP_SYSTEMTYPE="workstation"
BOOTSTRAP_USERNAME="simon"
BOOTSTRAP_TARGET="/dev/sdx"
BOOTSTRAP_MOUNT="/media/root"
BOOTSTRAP_SWAP=true
### !!! CONFIG !!! ###

# partitioning
# /dev/sdx1 - /boot - at least 5gb
# /dev/sdx2 - /     - 
# /dev/sdx3 - swap  - 
# MISSING

# format
mkfs.ext3 -L boot ${BOOTSTRAP_TARGET}1
luksformat ${BOOTSTRAP_TARGET}2
mkswap ${BOOTSTRAP_TARGET}3

# luks swap
# MISSING

# unlock & mount root
cryptsetup luksOpen ${BOOTSTRAP_TARGET}2 root
mount /dev/mapper/root ${BOOTSTRAP_MOUNT}

# bootstrap system
cd ${BOOTSTRAP_MOUNT}
debootstrap --include=vim-nox,git,sudo testing . http://ftp2.de.debian.org/debian 

# /boot/
mount ${BOOTSTRAP_TARGET}1 ${BOOTSTRAP_MOUNT}/mnt/
mv ${BOOTSTRAP_MOUNT}/boot/* ${BOOTSTRAP_MOUNT}/mnt/ 2>/dev/null
umount ${BOOTSTRAP_MOUNT}/mnt/
mount ${BOOTSTRAP_TARGET}1 ${BOOTSTRAP_MOUNT}/boot/

# mount stuff & chroot
mount -o bind /dev/ ${BOOTSTRAP_MOUNT}/dev/
mount -o bind /dev/pts ${BOOTSTRAP_MOUNT}/dev/pts
mount -o bind /sys/ ${BOOTSTRAP_MOUNT}/sys/
mount -o bind /proc/ ${BOOTSTRAP_MOUNT}/proc/

# fstab
echo -e "${BOOTSTRAP_TARGET}1\t/boot\text3\tdefault\t0 0" > ${BOOTSTRAP_MOUNT}/etc/fstab
echo -e "/dev/mapper/root\t/\tbtrfs\tautodefrag,noatime,rw,ssd,compress,thread_pool=32\t0 0" >> ${BOOTSTRAP_MOUNT}/etc/fstab

# crypttab
echo -e "root\t${BOOTSTRAP_TARGET}2\tnone\tluks" > ${BOOTSTRAP_MOUNT}/etc/crypttab

# moving step2 into chroot
mkdir ${BOOTSTRAP_MOUNT}/installer/
cp install_step*.sh ${BOOTSTRAP_MOUNT}/installer/
cp -r ../.hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
cp -r ../.packages/ ${BOOTSTRAP_MOUNT}/installer/packages/

# start step2 via chroot
chroot . "cd /installer/ && ./install_step2.sh"

