#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"

pwlist="/share/projects/password lists/archive_passwords.txt"
pwcount=$( wc -l "$pwlist" | awk {'print $1'} )
file=$@

if ( unrar l -p- ${file} 2>/dev/null >&2 )
then
    echo -e "${GREEN}RAR IS UNPROTECTED${NORMAL}"
    exit 0
fi

echo    
echo "Trying to crack rar file '${file}'"
echo "Using wordlist '${pwlist}' (${pwcount} entries)"
echo    

passwords=$( grep -v "^$" "${pwlist}" | tac )
for pw in $passwords
do 
    echo "Trying password '$pw'"
    if ( unrar l -p${pw} ${file} 2>/dev/null >&2 )
    then
        echo -e "\n${GREEN}PASSWORD FOUND: ${pw}${NORMAL}\n"
        exit 0
    fi
done

echo -e "\n${RED}PASSWORD NOT FOUND${NORMAL}\n"
exit 1

