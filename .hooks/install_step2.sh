#!/bin/bash

if ( echo $0 | grep -q -e "^/*installer/" )
then
    cd /installer/
fi

if [ ! -r ./settings.sh ]
then
    echo "[ERROR] Could not find 'settings.sh' while executing 'install_step2.sh'"
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
            echo ">>> Executing './hooks/loader.sh ${hook}'"
            ./hooks/loader.sh $hook
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
