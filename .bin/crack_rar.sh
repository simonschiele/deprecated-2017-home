#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"

file=$@

if ( unrar l ${file} 2>/dev/null >&2 )
then
    echo -e "${GREEN}RAR IS UNPROTECTED${NORMAL}"
    exit 0
fi

passwords=$( grep -v "^$" /share/projects/password\ lists/archive_passwords.txt )
for pw in $passwords
do 
    echo "Trying password '$pw'"
    echo "unrar -p${pw} l ${file} 2>/dev/null >&2"
    false
    if [ $? == 0 ]
    then
        echo -e "${GREEN}PASSWORD FOUND: ${pw}${NORMAL}"
        exit 0
    fi
done

echo -e "${RED}PASSWORD NOT FOUND${NORMAL}"
exit 1

