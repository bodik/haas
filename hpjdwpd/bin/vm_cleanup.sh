#!/bin/sh

INSTALL_DIR="/opt/jdwpd"
echo "INFO: $0"

systemctl stop jdwpd

find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
truncate --size 0 ${INSTALL_DIR}/racert/registered-at-warden-server

find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
find ${INSTALL_DIR}/bin -type f -name '*cfg' -exec shred --force --remove {} \;

