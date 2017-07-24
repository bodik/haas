#!/bin/sh

echo "INFO: $0"

systemctl stop cowrie
find /opt/hostcert -type f -exec shred --force --remove {} \;
find /opt/cowrie/log -type f -exec shred --force --remove {} \;
find /opt/cowrie/warden -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/cowrie/registered-at-warden-server

