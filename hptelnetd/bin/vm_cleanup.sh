#!/bin/sh

INSTALL_DIR="/opt/telnetd"
echo "INFO: $0"

systemctl stop telnetd

find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
truncate --size 0 ${INSTALL_DIR}/racert/registered-at-warden-server

find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
find ${INSTALL_DIR}/bin -type f -name '*cfg' -exec shred --force --remove {} \;

