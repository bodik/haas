#!/bin/sh

echo "INFO: $0"

systemctl stop dionaea
find /opt/hostcert -type f -exec shred --force --remove {} \;
find /opt/dionaea/var/dionaea -maxdepth 1 -type f -exec shred --force --remove {} \;
find /opt/dionaea/var/dionaea/binaries /opt/dionaea/var/dionaea/bistreams /opt/dionaea/var/dionaea/roots -type f -exec shred --force --remove {} \;
find /opt/dionaea/var/dionaea/bistreams/ -mindepth 1 -type d -exec -delete;
find /opt/dionaea/warden /opt/dionaea/etc/dionaea/ -type f -name '*cfg' -exec shred --force --remove {} \;
truncate --size 0 /opt/dionaea/registered-at-warden-server

