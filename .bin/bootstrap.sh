#!/bin/bash

### !!! CONFIG !!! #########################################
#
# best overwrite by export before running this script:
# export BOOTSTRAP_HOSTNAME="virt12.cnet.loc"
# export BOOTSTRAP_TARGET="/dev/sda"
# export BOOTSTRAP_SYSTEMTYPE="workstation"
# ./bootstrap.sh
#

BOOTSTRAP_HOSTNAME=${BOOTSTRAP_HOSTNAME:-"test.cnet.loc"}
BOOTSTRAP_SYSTEMTYPE=${BOOTSTRAP_SYSTEMTYPE:-"minimal"}
BOOTSTRAP_USERNAME=${BOOTSTRAP_USERNAME:-"simon"}
BOOTSTRAP_TARGET=${BOOTSTRAP_TARGET:-"/dev/sdX"}
BOOTSTRAP_MOUNT=${BOOTSTRAP_MOUNT:-"/media/root"}
BOOTSTRAP_64=${BOOTSTRAP_64:-false}
BOOTSTRAP_SSD=${BOOTSTRAP_SSD:-true}
BOOTSTRAP_SUITE=${BOOTSTRAP_SUITE:-"testing"}
BOOTSTRAP_MIRROR=${BOOTSTRAP_MIRROR:-"http://ftp2.de.debian.org/debian"}
BOOTSTRAP_PACKAGES="vim-nox,git,sudo,etckeeper,locales,kbd,keyboard-configuration,tzdata,ntpdate"
############################################################

errorexit() {
    echo "[ERROR] ${@}" 
    exit 1
}

get_size() {
    parted -s -m -l | grep "^${@}" | cut -f'2' -d':'
}

echo
echo "Simons bootstrap wrapper"
echo
echo "Configuration by export like:"
echo "> export BOOTSTRAP_HOSTNAME=\"testhost.cnet.loc\""
echo
echo "Possible config variables:"
echo -e "\tBOOTSTRAP_HOSTNAME\t\t(like \"testhost.cnet.loc\")"
echo -e "\tBOOTSTRAP_SYSTEMTYPE\t\t(like \"workstation\")"
echo -e "\tBOOTSTRAP_USERNAME\t\t(like \"simon\")"
echo -e "\tBOOTSTRAP_TARGET\t\t(like \"/dev/sdc\")"
echo -e "\tBOOTSTRAP_MOUNT\t\t\t(like \"/media/root\")"
echo -e "\tBOOTSTRAP_64\t\t\t(like true|false)"
echo -e "\tBOOTSTRAP_SSD\t\t\t(like true|false)"
echo -e "\tBOOTSTRAP_SUITE\t\t\t(like \"testing\")"
echo -e "\tBOOTSTRAP_MIRROR\t\t(like \"http://ftp2.de.debian.org/debian\")"
echo -e "\tBOOTSTRAP_PACKAGES\t\t(like \"emacs,mercurial\")"
echo
echo "Settings at the moment:"
echo -e "\tsystemtype: ${BOOTSTRAP_SYSTEMTYPE}"
echo -e "\ttarget: ${BOOTSTRAP_TARGET}"
echo -e "\tdefault user: ${BOOTSTRAP_USERNAME}"
echo -e "\tsuite: ${BOOTSTRAP_SUITE}"
echo -e "\tmirror: ${BOOTSTRAP_MIRROR}"
echo -e "\t64bit: ${BOOTSTRAP_64}"
echo -e "\tSSD: ${BOOTSTRAP_SSD}"
echo
echo ">>> STARTING"
echo

if ! [ -b ${BOOTSTRAP_TARGET} ] 
then
    errorexit "Device ${BOOTSTRAP_TARGET} not found"
fi

if [ -z "$( which parted )" ]
then
    errorexit "Depends 'parted' not found"
fi

echo "This will destroy everything on device ${BOOTSTRAP_TARGET}"'!!!'
read -p "To continue type uppercase 'yes': "
if [ "x${REPLY}" != "xYES" ]; then
    echo "Canceled"
    exit 2 
fi

echo ">>> Creating log/"
mkdir -p log/

echo ">>> Checking drive size"
if ! [ "xGB" == "x$( get_size ${BOOTSTRAP_TARGET} | sed 's|[0-9,\.]||g' )" ]
then
    echo "Drive size not in GB. Can not continue."
    exit 1 
fi

SMALL=false
if [ $( get_size ${BOOTSTRAP_TARGET} | sed 's|[A-Za-z]||g' | cut -f'1' -d'.' | cut -f'1' -d',' ) -lt 25 ]
then
    message "error" "Device is only $( get_size ${BOOTSTRAP_TARGET} ). Should be at least 25GB. Will do small partition type."
    SMALL=true
fi

echo ">>> Partitioning Drive '${BOOTSTRAP_TARGET}'"
echo "> Creating Partition Label"
parted -s ${BOOTSTRAP_TARGET} mklabel msdos >> log/step1.log

if ( ${SMALL} )
then
    echo "> Creating '/boot' (${BOOTSTRAP_TARGET}1, 1024MB)"
    parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M 1025M >> log/step1.log

    if ( ${BOOTSTRAP_SSD} )
    then
        echo "> Creating '/' (${BOOTSTRAP_TARGET}2, )"
        parted -s ${BOOTSTRAP_TARGET} mkpart primary 1025M $( get_size ${BOOTSTRAP_TARGET} ) >> log/step1.log
    else
        echo "> Creating '/' (${BOOTSTRAP_TARGET}2, )"
        parted -s ${BOOTSTRAP_TARGET} mkpart primary 1025M $( get_size ${BOOTSTRAP_TARGET} ) >> log/step1.log
    
        echo "> Creating 'swap' (${BOOTSTRAP_TARGET}3, 512MB) (MISSING)"
        #parted -s ${BOOTSTRAP_TARGET} mkpart primary 4096M 4608M >> log/step1.log
    fi
else
    echo "> Creating '/boot' (${BOOTSTRAP_TARGET}1, 6145MB)"
    parted -s ${BOOTSTRAP_TARGET} mkpart primary 1M 6145M >> log/step1.log

    if ( ${BOOTSTRAP_SSD} )
    then
        echo "> Creating '/' (${BOOTSTRAP_TARGET}2, )"
        parted -s ${BOOTSTRAP_TARGET} mkpart primary 1025M $( get_size ${BOOTSTRAP_TARGET} ) >> log/step1.log
    else
        echo "> Creating '/' (${BOOTSTRAP_TARGET}2, )"
        parted -s ${BOOTSTRAP_TARGET} mkpart primary 1025M $( get_size ${BOOTSTRAP_TARGET} ) >> log/step1.log
    
        echo "> Creating 'swap' (${BOOTSTRAP_TARGET}3, 512MB) (MISSING)"
        #parted -s ${BOOTSTRAP_TARGET} mkpart primary 4096M 4608M >> log/step1.log
    fi
fi

echo ">>> Setup Luks for '/' on ${BOOTSTRAP_TARGET}2" 
if ! ( luksformat ${BOOTSTRAP_TARGET}2 )
then
    errorexit "Luksformat not successful"
fi

echo ">>> Unlock created device ${BOOTSTRAP_TARGET}2"
if ! ( cryptsetup luksOpen ${BOOTSTRAP_TARGET}2 root )
then
    errorexit "Could not unlock Luks device"
fi

echo ">>> Format partitions"
echo "> Format '/boot' (${BOOTSTRAP_TARGET}1, ext3)"
mkfs.ext3 -q -L boot ${BOOTSTRAP_TARGET}1 >> log/step1.log

echo "> Format '/dev/mapper/root' (${BOOTSTRAP_TARGET}2, btrfs)"
mkfs.btrfs -L root /dev/mapper/root >> log/step1.log

if ! ( ${BOOTSTRAP_SSD} )
then
    echo "> Format 'swap' (${BOOTSTRAP_TARGET}3, swap) (MISSING)"
    #mkswap -L swap ${BOOTSTRAP_TARGET}3 >> log/step1.log

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
cp bootstrap*.sh ${BOOTSTRAP_MOUNT}/installer/
if [ -r ../hooks/helper.sh ]
then
    cp -r ../hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r ../packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r ../.hooks/helper.sh ]
then
    cp -r ../.hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r ../.packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r hooks/helper.sh ]
then
    cp -r hooks/ ${BOOTSTRAP_MOUNT}/installer/hooks/
    cp -r packages/ ${BOOTSTRAP_MOUNT}/installer/packages/
elif [ -r .hooks/helper.sh ]
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
echo "BOOTSTRAP_SSD=${BOOTSTRAP_SSD}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh
echo "BOOTSTRAP_PACKAGES=${BOOTSTRAP_PACKAGES}" >> ${BOOTSTRAP_MOUNT}/installer/settings.sh

cat >${BOOTSTRAP_MOUNT}/installer/bootstrap2.sh << 'EOF'
#!/bin/bash

errorexit() {
    echo "[ERROR] ${@}" 
    exit 1
}

if ( echo $0 | grep -q -e "^/*installer/" )
then
    cd /installer/
fi

if [ ! -r ./settings.sh ]
then
    echo "[ERROR] Could not find 'settings.sh' while executing 'bootstrap2.sh'"
    exit 1
fi

HOOKS=true
if [ ! -d ./hooks/ ]
then
    echo "[WARNING] Could not find hooks/ folder"
    HOOKS=false
fi

PACKAGES=true
if [ ! -d ./packages/ ]
then
    echo "[WARNING] Could not find packages/ folder"
    PACKAGES=false
fi

echo ">>> Starting step2 (inside chroot)"

echo ">>> Reading config settings"
eval $( grep ^BOOTSTRAP_ ./settings.sh )
BOOTSTRAP_HOME="/home/${BOOTSTRAP_USERNAME}"

echo ">>> Setting up locales"
echo "set locales/default_environment_locale de_DE.UTF-8" | sudo debconf-communicate
echo "set locales/locales_to_be_generated de_DE.UTF-8 UTF-8" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive locales

echo ">>> Reconfiguring Debconf"
echo "set debconf/frontend Dialog" | sudo debconf-communicate
echo "set debconf/priority high" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive debconf

echo ">>> Setting up keyboard (via debconf)"
echo "set keyboard-configuration/layout German" | sudo debconf-communicate
echo "set keyboard-configuration/variant German - German (eliminate dead keys)" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive keyboard-configuration

echo ">>> Setting clock/timezone"
echo "set tzdata/Areas Europe" | sudo debconf-communicate
echo "set tzdata/Zones/Etc UTC" | sudo debconf-communicate
echo "set tzdata/Zones/Europe Berlin" | sudo debconf-communicate
dpkg-reconfigure -f noninteractive tzdata
hwclock --utc
ntpdate time.fu-berln.de
hwclock --systohc

echo ">>> Creating default User '${BOOTSTRAP_USERNAME}'"
useradd -m -U -s /bin/bash ${BOOTSTRAP_USERNAME}

echo ">>> Changing password for User '${BOOTSTRAP_USERNAME}'"
passwd ${BOOTSTRAP_USERNAME}

echo ">>> Changing password for User 'root'"
passwd root

echo ">>> Setting up apt (better use hook)"
echo 'deb http://security.debian.org/ testing/updates main contrib non-free' > /etc/apt/sources.list
echo 'deb http://ftp2.de.debian.org/debian testing main contrib non-free' >> /etc/apt/sources.list
apt-get update

echo ">>> Checking out home.git (+ subrepos)"
rm -rf ${BOOTSTRAP_HOME} 
git clone --recursive http://simon.psaux.de/git/home.git ${BOOTSTRAP_HOME}
chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME}/ -R
. ${BOOTSTRAP_HOME}/.bashrc
mkdir ${BOOTSTRAP_HOME}/Downloads
    
echo ">>> Installing Kernel and Bootloader (better use hook)"
apt-get install grub2 linux-image-2.6-686-pae linux-headers-2.6-686-pae firmware-linux-free firmware-linux-nonfree firmware-realtek firmware-iwlwifi
    
echo ">>> Writing ${BOOTSTRAP_HOME}/.system.conf"
system_conf=${BOOTSTRAP_HOME}/.system.conf
echo -e "hostname=\"$( echo $BOOTSTRAP_HOSTNAME | cut -f'1' -d'.' )\"" > $system_conf
echo -e "domain=\"${BOOTSTRAP_DOMAIN:-$( echo $BOOTSTRAP_HOSTNAME | cut -s -f'2-' -d'.' )}\"" >> $system_conf
echo -e "systemtype=\"${BOOTSTRAP_SYSTEMTYPE}\"" >> $system_conf
echo -e "username=\"${BOOTSTRAP_USERNAME}\"" >> $system_conf

if ( $PACKAGES )
then
    echo ">>> Installing packages for systemtype '${BOOTSTRAP_SYSTEMTYPE}'"
    apt-get install $( cat $( grep '^\.\ ' ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed 's|^\. *||g' | sed 's|^|./|g' | xargs ) ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' -e 's|[ ]|\n|g' | sed '/^$/d' | sort -u | xargs )
fi

if ! ( $HOOKS )
then
    echo ">>> Executing non-optional Hooks for systemtype '${BOOTSTRAP_SYSTEMTYPE}'"
    find hooks/* | while read hook
    do 
        if (( grep -iq ^hook_systemtype.*${BOOTSTRAP_SYSTEMTYPE} $hook ) && ( grep -iq ^hook_optional.*false $hook ))
        then 
            echo ">>> Executing './${hook}'"
            ./${hook}
        fi
    done
fi

groups="audio video plugdev netdev fuse sudo"
echo ">>> Adding User '${BOOTSTRAP_USERNAME}' to default groups:"
echo "> $groups"
for group in $groups
do
    usermod -a -G ${group} ${BOOTSTRAP_USERNAME}
done

echo ">>> Setting minimal permissions (better use hook)"
chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME} -R 
find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;

# finished
echo
echo 'Bootstrap + Autoconfiguration is finished!'
echo 
echo 'Please copy/install/configure by hand:'
echo '* fonts'
echo '* keys' 
echo 
echo 'Enjoy your new system!' 
echo 

EOF
chmod 770 ${DESTDIR}/scripts/local-top/sleep

echo ">>> Starting step2 via chroot"
chroot ${BOOTSTRAP_MOUNT} /bin/bash /installer/bootstrap2.sh 

