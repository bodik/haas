#!/bin/sh

if [ -f ${INSTALL_DIR}/bin/uchotcp.py ]; then

	INSTALL_DIR=/opt/uchotcp
	systemctl stop uchotcp
	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	truncate --size 0 ${INSTALL_DIR}/racert/registered-at-warden-server
	find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/bin -type f -name '*cfg' -exec shred --force --remove {} \;
fi

if [ -f ${INSTALL_DIR}/bin/uchoudp.py ]; then

	INSTALL_DIR=/opt/uchoudp
	systemctl stop uchoudp
	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	truncate --size 0 ${INSTALL_DIR}/racert/registered-at-warden-server
	find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/bin -type f -name '*cfg' -exec shred --force --remove {} \;
fi

