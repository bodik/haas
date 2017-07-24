#!/bin/sh

echo "INFO: $0"

systemctl stop uchotcp
systemctl stop uchoudp

find /opt/hostcert -type f -exec shred --force --remove {} \;

find /opt/uchotcp/log -type f -exec shred --force --remove {} \;
find /opt/uchotcp/bin -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/uchotcp/bin/registered-at-warden-server

find /opt/uchoudp/log -type f -exec shred --force --remove {} \;
find /opt/uchoudp/bin -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/uchoudp/bin/registered-at-warden-server

