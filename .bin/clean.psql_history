#!/bin/sh

for file in /home/*/.psql_history /root/.psql_history /var/lib/postgresql/.psql_history
do
    sed -i "/.*password.*/Id" $file
    sed -i "/.*passwd.*/Id" $file
    sed -i "/.*md5.*/Id" $file
    sed -i "/.*sha1.*/Id" $file
    sed -i "/.*salt.*/Id" $file
done

