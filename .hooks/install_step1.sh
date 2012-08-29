#!/bin/bash

### !!! CONFIG !!! #########################################
#
# best overwrite by export before running this script:
# export BOOTSTRAP_HOSTNAME="virt12.cnet.loc"
# export BOOTSTRAP_TARGET="/dev/sda"
# export BOOTSTRAP_SYSTEMTYPE="workstation"
# ./install_step1.sh
#

BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME:-"test.cnet.loc"}
BOOTSTRAP_SYSTEMTYPE=${BOOTSTRAP_SYSTEMTYPE:-"minimal"}
BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME:-"simon"}
BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET:-"/dev/sdX"}
BOOTSTRAP_MOUNT=${BOOTSTRAP_MOUNT:-"/media/root"}
BOOTSTRAP_64=${BOOTSTRAP_64:-false}
BOOTSTRAP_SWAP=${BOOTSTRAP_SWAP:-true}
BOOTSTRAP_SSD=${BOOTSTRAP_SSD:-true}
BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE:-"testing"}
BOOTSTRAP_MIRROR=${BOOTSTRAP_MIRROR:-"http://ftp2.de.debian.org/debian"}
BOOTSTRAP_PACKAGES="vim-nox,git,sudo,etckeeper,locales,kbd,keyboard-configuration,tzdata,ntpdate"
############################################################

errorexit() {
    echo "[ERROR] ${@}" 
    exit 1
}

echo
echo "Simons bootstrap wrapper"
echo
echo "systemtype: ${BOOTSTRAP_SYSTEMTYPE}"
echo "target: ${BOOTSTRAP_TARGET}"
echo "default user: ${BOOTSTRAP_USERNAME}"
echo "suite: ${BOOTSTRAP_SUITE}"
echo "mirror: ${BOOTSTRAP_MIRROR}"
echo "64bit: ${BOOTSTRAP_64}"
echo "SWAP: ${BOOTSTRAP_SWAP}"
echo "SSD: ${BOOTSTRAP_SSD}"
echo
echo "This will destroy everything on device ${BOOTSTRAP_TARGET}"'!!!'
read -p "To continue type uppercase 'yes': "
if [ "x${REPLY}" != "xYES" ]; then
    echo "Canceled"
    exit 2 
else
    echo ">>> Starting installation"
fi

echo ">>> Creating log/"
mkdir -p log/

echo ">>> Partitioning Drive '${BOOTSTRAP_TARGET}' (MISSING)"
echo "> Creating Partition Label"
parted -s ${BOOTSTRAP_TARGET} mklabel msdos >> log/step1.log

echo "> Creating '/boot' (${BOOTSTRAP_TARGET}1, 1024MB)"
parted -s ${BOOTSTRAP_TARGET} mkpart primary 0 1024M >> log/step1.log

echo "> Creating '/' (${BOOTSTRAP_TARGET}2, 3072MB)"
parted -s ${BOOTSTRAP_TARGET} mkpart primary 1024M 4096M >> log/step1.log

if ( ${BOOTSTRAP_SWAP} )
then
    echo "> Creating 'swap' (${BOOTSTRAP_TARGET}3, 512MB)"
    parted -s ${BOOTSTRAP_TARGET} mkpart primary 4096M 4608M >> log/step1.log
fi

echo ">>> Setup Luks for '/' on ${BOOTSTRAP_TARGET}2" 
luksformat ${BOOTSTRAP_TARGET}2

echo ">>> Unlock created device ${BOOTSTRAP_TARGET}2"
cryptsetup luksOpen ${BOOTSTRAP_TARGET}2 root 

echo ">>> Format partitions"
echo "> Format '/boot' (${BOOTSTRAP_TARGET}1, ext3)"
mkfs.ext3 -q -L boot ${BOOTSTRAP_TARGET}1 >> log/step1.log

echo "> Format '/dev/mapper/root' (${BOOTSTRAP_TARGET}2, btrfs)"
mkfs.btrfs -L root /dev/mapper/root >> log/step1.log

if ( ${BOOTSTRAP_SWAP} )
then
    echo "> Format 'swap' (${BOOTSTRAP_TARGET}3, swap)"
    mkswap -L swap ${BOOTSTRAP_TARGET}3 >> log/step1.log

    echo ">>> Setting up random encrypted swap (MISSING)"
fi

echo ">>> Mounting '/' to ${BOOTSTRAP_MOUNT}"
if ! [ -d ${BOOTSTRAP_MOUNT} ]
then
    mkdir -p ${BOOTSTRAP_MOUNT}
fi

if ! ( mount /dev/mapper/root ${BOOTSTRAP_MOUNT}  >> log/step1.log )
then
    errorexit "Could not mount /dev/mapper/root"
fi

echo ">>> Starting Bootstrap (debian ${BOOTSTRAP_SUITE} via ${BOOTSTRAP_MIRROR})"
echo "> This may take a while..."
if ! ( debootstrap --include=${BOOTSTRAP_PACKAGES} ${BOOTSTRAP_SUITE} ${BOOTSTRAP_MOUNT} ${BOOTSTRAP_MIRROR} >> log/step1.log )
then
    echo ">>> Bootstrap Finished with errors"
    errorexit "Bootstrap failed"
else
    echo ">>> Bootstrap Finished Successfully"
fi

echo ">>> Setup /boot/"
mount ${BOOTSTRAP_TARGET}1 ${BOOTSTRAP_MOUNT}/mnt/ >> log/step1.log
mv ${BOOTSTRAP_MOUNT}/boot/* ${BOOTSTRAP_MOUNT}/mnt/ >> log/step1.log 2>&1
umount ${BOOTSTRAP_MOUNT}/mnt/ >> log/step1.log
mount ${BOOTSTRAP_TARGET}1 ${BOOTSTRAP_MOUNT}/boot/ >> log/step1.log

echo ">>> Mounting"
echo "> mount '/dev/'"
mount -o bind /dev/ ${BOOTSTRAP_MOUNT}/dev/ >> log/step1.log

echo "> mount '/dev/pts'"
mount -o bind /dev/pts ${BOOTSTRAP_MOUNT}/dev/pts >> log/step1.log

echo "> mount '/sys/'"
mount -o bind /sys/ ${BOOTSTRAP_MOUNT}/sys/ >> log/step1.log

echo "> mount '/proc/'"
mount -o bind /proc/ ${BOOTSTRAP_MOUNT}/proc/ >> log/step1.log

echo ">>> Creating /etc/fstab"
echo -e "${BOOTSTRAP_TARGET}1\t/boot\text3\tdefault\t0 0" > ${BOOTSTRAP_MOUNT}/etc/fstab
echo -e "/dev/mapper/root\t/\tbtrfs\tautodefrag,noatime,rw,ssd,compress,thread_pool=32\t0 0" >> ${BOOTSTRAP_MOUNT}/etc/fstab

echo ">>> Creating /etc/crypttab"
echo -e "root\t${BOOTSTRAP_TARGET}2\tnone\tluks" > ${BOOTSTRAP_MOUNT}/etc/crypttab

echo ">>> Copy installer, hooks and packagelists to ${BOOTSTRAP_MOUNT}/installer/ for step2"
mkdir ${BOOTSTRAP_MOUNT}/installer/
cp install_step*.sh ${BOOTSTRAP_MOUNT}/installer/
if [ -r ../hooks/loader.sh ]
then
    cp -r ../hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r ../packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r ../.hooks/loader.sh ]
then
    cp -r ../.hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r ../.packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r hooks/loader.sh ]
then
    cp -r hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r .hooks/loader.sh ]
then
    cp -r .hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r .packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
else
    echo "[WARNING] NO HOOKS OR PACKAGES DIRECTORY FOUND"
fi

echo ">>> Copy installer logfiles to ${BOOTSTRAP_MOUNT}/installer/"
cp -r log/ ${BOOTSTRAP_MOUNT}/installer/

echo ">>> Creating settings.sh for step2"
echo '#!/bin/bash' > ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_SYSTEMTYPE=${BOOTSTRAP_SYSTEMTYPE}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_MIRROR=${BOOTSTRAP_MIRROR}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_MOUNT=${BOOTSTRAP_MOUNT}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_64=${BOOTSTRAP_64}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_SWAP=${BOOTSTRAP_SWAP}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_SSD=${BOOTSTRAP_SSD}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_PACKAGES=${BOOTSTRAP_PACKAGES}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh

echo ">>> Starting step2 via chroot"
chroot ${BOOTSTRAP_MOUNT} /bin/bash /installer/install_step2.sh 

