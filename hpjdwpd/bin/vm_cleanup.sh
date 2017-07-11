#!/bin/sh

echo "INFO: $0"

systemctl stop jdwpd
find /opt/hostcert -type f -exec shred --force --remove {} \;
find /opt/jdwpd/log -type f -exec shred --force --remove {} \;
find /opt/jdwpd/bin -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/jdwpd/bin/registered-at-warden-server

