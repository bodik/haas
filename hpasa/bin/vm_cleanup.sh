#!/bin/sh

INSTALL_DIR=/opt/asa

if [ -f ${INSTALL_DIR}/bin/asa_server.py ]; then

	systemctl stop asa

	find ${INSTALL_DIR}/asacert -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/warden -type f -name '*cfg' -exec shred --force --remove {} \;
fi
