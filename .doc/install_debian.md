Installing Debian the simon-way
-------------------------------

This describes the typical install process I choose for my private systems.
This workflow is not usable or at least practival for anyone else, but maybe
a few snippits from this are helpfull for others.

[TOC]

== boot from usb stick ==
* grml
* debian live

== partitioning-, raid- & luks-setup ==
* explain with windows

* cfdisk /dev/sda
* [raid] sfdisk -d /dev/sda > disk
* [raid] sfdisk /dev/sdb < disk
* [raid] mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
* [raid] mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2
* mkfs.ext3 -L boot /dev/1 (raid: /dev/md0)
* mkswap -L swap /dev/3
* cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/2
* cryptsetup luksOpen /dev/sda2 root
* mkfs.btrfs -L root /dev/mapper/root
* mkdir /media/root
* mount /dev/mapper/root /media/root

== bootstraping the system ==
* cd /media/root
* debootstrap --include=git,etckeeper,sudo,vim-nox,fuse --components=main,contrib,non-free unstable . http://ftp2.de.debian.org/debian
* mount -o bind /proc /media/root/proc/
* mount -o bind /dev /media/root/dev/
* mount -o bind /dev/pts /media/root/dev/pts
* mount -o bind /sys /media/root/sys/

== setup user and home ==
* git clone --recursive http://simon.psaux.de/git/home.git home/simon
* mount /dev/sda1 /media/root/boot
* chroot /media/root/ /bin/bash
    * adduser --no-create-home --home /home/simon/ simon
    * LANG=C addgroup simon sudo
    * LANG=C addgroup simon fuse
    * LANG=C addgroup simon dialout
    * LANG=C addgroup simon plugdev
    * LANG=C addgroup simon netdev
    * LANG=C addgroup simon audio
    * LANG=C addgroup simon cdrom
    * LANG=C addgroup simon floppy

== setup system ==
* chroot /media/root/ /bin/bash
    * sudo vi /etc/hostname
    * ...
    * cd /root/
    * rm .bashrc
    * ln -s /home/simon/.bashrc .
    * ln -s /home/simon/.vim .
    * ln -s /home/simon/.vimrc .
    * ln -s /home/simon/.gitconfig .
    * ln -s /home/simon/.lib .
    * chown simon: /home/simon/ -R
    * chmod 700 /home/simon
    * su - simon
        * cd /etc/
        * sudo etckeeper init
        * sudo vi /etc/.gitignore
        * ->  /initramfs-tools/hooks*
        * ->  /initramfs-tools/hooks/**/*
        * sudo git commit .gitignore -m "added initramfs-hooks to gitignore"
        * cd /home/simon
        * echo 'hostname="cpad"' > .system.conf
        * echo 'domain="cnet"' >> .system.conf
        * echo 'systemtype="laptop"' >> .system.conf
        * echo 'username="simon"' >> .system.conf
        * echo '#################################################' >> .system.conf
        * sudo apt-get install $( debian_packages_list $(grep ^systemtype ~/.system.conf | cut -f'2-' -d'=' | sed 's|[\"]||g') )
        * # Need to get 810 MB of archives.
        * sudo apt-get install linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-free firmware-linux-nonfree dropbear grub2
        * [raid] sudo apt-get install mdadm
        * cd /etc/initramfs-tools/
        * sudo rmdir hooks
        * sudo git clone http://simon.psaux.de/git/initramfs-hooks.git hooks
        * sed -i 's|filemode.*=.*|filemode = false|g' hooks/.git/config
        * sudo chmod +x hooks/network.sh
        * sudo chmod +x hooks/cryptoroot.sh
        * sudo vi hooks/network.sh hooks/cryptoroot.sh -> config
        * sudo vi /etc/fstab
        * [nonraid] -> /dev/mapper/root    /       btrfs   noatime,rw,ssd  0   0
        * [nonraid] -> /dev/mapper/swap    none    swap    sw              0   0
        * [nonraid] -> /dev/sda1           /boot   auto    auto,defaults   0   0
        * [raid] -> /dev/mapper/root    /       btrfs   noatime,rw,ssd  0   0
        * [raid] -> /dev/mapper/swap1   none    swap    sw              0   0
        * [raid] -> /dev/mapper/swap2   none    swap    sw              0   0
        * [raid] -> /dev/md0            /boot   auto    auto,defaults   0   0
        * sudo vi /etc/crypttab
        * [nonraid] -> root    /dev/sda2   none            luks
        * [nonraid] -> swap    /dev/sda3   /dev/random     swap,cipher=aes,size=128,hash=ripemd160
        * [raid]    -> root    /dev/md1    none            luks
        * [raid]    -> swap1    /dev/sda3   /dev/random     swap,cipher=aes,size=128,hash=ripemd160
        * [raid]    -> swap2    /dev/sdb3   /dev/random     swap,cipher=aes,size=128,hash=ripemd160
        * [workstation|laptop] ssh-keygen -b 521 -t ecdsa or. ssh-keygen -t rsa -b 4096
            * [workstation|laptop] add key to private gitolite, maybe work gitosis and maybe github
        * sudo rmdir /usr/local/src/ /media/
        * sudo ln -s /usr/src/ /usr/local/src
        * sudo ln -s /mnt/ /media
        * sudo chmod 777 /usr/src/
        * [server] sudo mkdir -p /mnt/iso /mnt/remote /mnt/tmp
        * [workstation|laptop] sudo mkdir -p /mnt/iso /mnt/remote /mnt/tmp /mnt/stick1 /mnt/stick2 /mnt/stick3 /mnt/stick4 /mnt/cfcard /mnt/sdcard /mnt/phone /mnt/tablet
        * [workstation|laptop] git clone http://simon.psaux.de/git/grub-stuff.git /usr/src/grub-suff
        * [workstation|laptop] sudo ln -s /usr/src/grub-stuff/50_grml /etc/grub.d/
        * sudo update-initramfs -k all -u
        * sudo update-grub
        * [raid] sudo grub-install /dev/sda
        * [raid] sudo grub-install /dev/sdb
        * [server] sudo /etc/init.d/[service] stop for: exim4 snort dbus mdadm ...
        * [workstation|laptop] sudo /etc/init.d/[service] stop for: ntp apache2 snort dbus ...
        * [laptop] apt-get install firmware-iwlwifi ...
        * [remote] sudo vi /etc/network/interfaces
        * dpkg-reconfigure keyboard-configuration
        * dpkg-reconfigure console-setup
        * dpkg-reconfigure tzdata
        * dpkg-reconfigure locales
        * for x in bluetooth dropbear snort ntp nmbd smbd samba samba-ad-dc saned openvpn pppd-dns apache2 avahi-daemon winbind ; do LANG=C update-rc.d -f $x remove ; done
        * exit
    * exit
* sync
* umount /media/root/dev/pts
* umount /media/root/dev
* umount /media/root/sys
* umount /media/root/sys
* umount /media/root/proc
* umount /media/root/boot
* umount /media/root
* cryptsetup luksClose root
* REBOOT -> LOGIN
kzuJcgGvZ27PLB
* hooks_run
* [workstation|laptop] configure terminal manually
* [workstation|laptop] configure awesome manually
* [workstation|laptop] configure chrome via sync

== setup firewall ==
* cd /usr/src
* git clone http://simon.psaux.de/git/firewall.git
* sudo vi /etc/default/firewall
