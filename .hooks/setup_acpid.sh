#!/bin/bash
hook_name=setup_acpid
hook_systemtypes="laptop"
hook_optional=true
hook_version=0.0
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

if ! [ -d /etc/acpi/ ]
then
    mkdir /etc/acpi/
fi

echo -e "event=button[ /]lid\naction=/etc/acpi/lid.sh\n" > /etc/acpi/events/lid

cat >/etc/acpi/lid.sh << 'EOF'
#!/bin/sh

grep -q closed /proc/acpi/button/lid/*/state
if [ $? = 0 ]
then
    hwclock --systohc
    xscreensaver-command -display :0 -lock
    echo mem > /sys/power/state
    hwclock --hctosys
fi

EOF
chmod +x /etc/acpi/lid.sh

