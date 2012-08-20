#!/bin/bash

if [ ! -e ./install_step1.sh ]
then
    echo "[ERROR] Could not find 'install_step1' while executing 'install_step1'"
    exit 1
fi

eval $( grep ^BOOTSTRAP_ ./install_step1.sh )
BOOTSTRAP_HOME="/home/${BOOTSTRAP_USERNAME}"

# create default user
adduser ${BOOTSTRAP_USERNAME}
passwd ${BOOTSTRAP_USERNAME}

# get sane homedir
rm -rf /home/${BOOTSTRAP_USERNAME}/ 
git clone --recursive http://simon.psaux.de/git/home.git /home/${BOOTSTRAP_USERNAME}
chown ${BOOTSTRAP_USERNAME}: ${BOOTSTRAP_HOME}/ -R
. /home/${BOOTSTRAP_USERNAME}/.bashrc

# write system.conf 
system_conf=${BOOTSTRAP_HOME}/.system.conf
echo -e "hostname=\"$( echo $BOOTSTRAP_HOSTNAME | cut -f'1' -d'.' )\"" > "$system_conf"
echo -e "domain=\"${BOOTSTRAP_DOMAIN:-$( echo $BOOTSTRAP_HOSTNAME | cut -s -f'2-' -d'.' )}\"" >> "$system_conf"
echo -e "systemtype=\"${BOOTSTRAP_SYSTEMTYPE}\"" >> "$system_conf"
echo -e "username=\"${BOOTSTRAP_USERNAME}\"" >> "$system_conf"

# link a few files to /root/
rm -rf /root/.bash* /root/.profile /root/.xsession /root/.vim/ /root/.gitconfig 2>/dev/null
ln -s /home/${BOOTSTRAP_USERNAME}/.bashrc /root/.bashrc
ln -s /home/${BOOTSTRAP_USERNAME}/.vim /root/.vim
ln -s /root/.vim/vimrc /root/.vimrc
ln -s /home/${BOOTSTRAP_USERNAME}/.gitconfig /root/.gitconfig
ln -s /home/${BOOTSTRAP_USERNAME}/.profile /root/.profile

# install packages
apt-get install $( cat $( grep '^\.\ ' ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed 's|^\. *||g' | sed 's|^|./|g' | xargs ) ./packages/${BOOTSTRAP_SYSTEMTYPE}.list | sed -e '/^\.[ ]/d' -e '/^#/d' -e '/^[ ]*$/d' -e 's|^\(.*\):\(.*\)$|\2|g' -e 's|^[ ]*||g' -e 's|[ ]|\n|g' | sed '/^$/d' | sort -u | xargs )

# execute hooks
find hooks/* | while read hook
do 
    if (( grep -iq ^hook_systemtype.*${BOOTSTRAP_SYSTEMTYPE} $hook ) && ( grep -iq ^hook_optional.*false $hook ))
    then 
        ./hooks/loader.sh $hook
    fi
done

# add ${BOOTSTRAP_USERNAME} to groups 
for GROUP in 'audio' 'video' 'plugdev' 'netdev' 'fuse' 'sudo'
do
    useradd -G $GROUP ${BOOTSTRAP_USERNAME}
done

# set permissions
# MISSING

# finished
echo
echo 'Bootstrap + Autoconfiguration is finished!'
echo 
echo 'Please copy/install/configure by hand:'
echo '* fonts'
echo '* keys' 
echo 
echo 'Enjoy your new system!' 

