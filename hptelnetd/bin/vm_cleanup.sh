#!/bin/sh

echo "INFO: $0"

systemctl stop telnetd

find /opt/hostcert -type f -exec shred --force --remove {} \;

find /opt/telnetd/log -type f -exec shred --force --remove {} \;
find /opt/telnetd/bin -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/telnetd/bin/registered-at-warden-server

