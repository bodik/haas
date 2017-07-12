#!/bin/sh

# Regenerate ssh keys
rm -f /etc/ssh/*_key*
dpkg-reconfigure openssh-server







# Delayled reboot
echo "\n\nWARN: Reboot in 5 seconds!\n\n"
sync
sleep 5
reboot 
