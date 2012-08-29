#!/bin/bash
[ -f /etc/motd.tail ] && cat /etc/motd.tail > /var/run/motd
uname -snrvm >> /var/run/motd
