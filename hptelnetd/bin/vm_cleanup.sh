#!/bin/sh

INSTALL_DIR=/opt/telnetd

if [ -f ${INSTALL_DIR}/bin/telnetd.py ]; then
	systemctl stop telnetd

	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/log -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/bin -type f -name '*cfg' -exec shred --force --remove {} \;
fi
