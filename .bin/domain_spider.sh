#!/bin/bash

SCRIPTNAME="domain_spider"
DOMAINLIST="/etc/default/${SCRIPTNAME}"
NAMESERVER="8.8.8.8"

if ! [ -r ${DOMAINLIST} ]
then
    echo "[Error] Could not read domainlist '${DOMAINLIST}'"
    exit 1
fi

cat ${DOMAINLIST} | while read entry
do
    for domain in $( eval echo ${entry} )
    do
        if (! ( dig @${NAMESERVER} ${domain} 2>&1 | grep -q "^${domain}" ) && ( whois ${domain} | grep -iq -e "^No match for" -e "^Status: free" -e "NOT FOUND" ))
        then
            echo -e "Domain '${domain}' seems to be available" 
        fi
    done
done

