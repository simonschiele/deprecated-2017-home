#!/bin/bash
hook_name=setup_initramfs-hooks
hook_systemtypes="minimal server workstation laptop"
hook_optional=false
hook_version=0.0

rm -rf /etc/initramfs-tools/hooks/
git clone http://simon.psaux.de/git/initramfs-hooks.git /etc/initramfs-tools/hooks

chmod +x /etc/initramfs-tools/hooks/network.sh /etc/initramfs-tools/hooks/cryptoroot.sh
sed -i "s/^hostname=.*/hostname=\"$( grep -e ^hostname -e ^domain ~/.system.conf | cut -f'2' -d'=' | sed 's|\"||g' | tr '\n' '.' | sed 's|\.$|\n|g' )\"/g" /etc/initramfs-tools/hooks/network.sh /etc/initramfs-tools/hooks/cryptoroot.sh 

update-initramfs -k all -u

