#!/bin/sh

# Regenerate ssh keys
/bin/rm -f /etc/ssh/*_key*
/usr/sbin/dpkg-reconfigure openssh-server
