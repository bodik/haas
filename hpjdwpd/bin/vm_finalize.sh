#!/bin/sh

INSTALL_DIR=/opt/jdwpd

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@


if [ -f ${INSTALL_DIR}/bin/jdwpd.py ]; then

	if [ ${AUTOTEST} -eq 0 ]; then
		pa.sh -e "warden3::cert { '${CLIENT_NAME}':
			destdir => '${INSTALL_DIR}',
			token => '${TOKEN}',
		}"
	fi
	pa.sh -e "class { 'hpjdwpd': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}' }"
fi

