#!/bin/sh

INSTALL_DIR=/opt/dioanea

if [ -f ${INSTALL_DIR}/bin/dionaea ]; then
	systemctl stop dionaea

	find ${INSTALL_DIR}/racert -type f -exec shred --force --remove {} \;
	truncate --size 0 ${INSTALL_DIR}/racert/registered-at-warden-server

	find ${INSTALL_DIR}/var/dionaea -maxdepth 1 -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/var/dionaea/binaries /opt/dionaea/var/dionaea/bistreams /opt/dionaea/var/dionaea/roots -type f -exec shred --force --remove {} \;
	find ${INSTALL_DIR}/var/dionaea/bistreams -mindepth 1 -type d -exec -delete;
	find ${INSTALL_DIR}/warden /opt/dionaea/etc/dionaea -type f -name '*cfg' -exec shred --force --remove {} \;
fi
