#!/bin/sh

INSTALL_DIR=/opt/cowrie

if [ -f ${INSTALL_DIR}/bin/cowrie ]; then

	systemctl stop cowrie

	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR} -maxdepth 1 -type f -name '*cfg' -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/warden -type f -name '*cfg' -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
fi
