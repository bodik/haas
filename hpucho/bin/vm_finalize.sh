#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@


INSTALL_DIR=/opt/uchotcp
if [ -f ${INSTALL_DIR}/bin/uchotcp.py ]; then
	if [ ${AUTOTEST} -eq 0 ]; then
		pa.sh -e "warden3::cert { '${CLIENT_NAME}.uchotcp':
			destdir => '${INSTALL_DIR}/racert',
			token => '${TOKEN}',
		}"
	fi
	pa.sh -e "class { 'hpucho::tcp': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}.uchotcp' }"
fi

INSTALL_DIR=/opt/uchoudp
if [ -f ${INSTALL_DIR}/bin/uchoudp.py ]; then
	if [ ${AUTOTEST} -eq 0 ]; then
		pa.sh -e "warden3::cert { '${CLIENT_NAME}.uchoudp':
			destdir => '${INSTALL_DIR}/racert',
			token => '${TOKEN}',
		}"
	fi

	pa.sh -e "class { 'hpucho::udp': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}.uchoudp' }"
fi

INSTALL_DIR=/opt/uchoweb
if [ -f ${INSTALL_DIR}/bin/uchoweb.py ]; then
	if [ ${AUTOTEST} -eq 0 ]; then
		pa.sh -e "warden3::cert { '${CLIENT_NAME}.uchoweb':
			destdir => '${INSTALL_DIR}',
			token => '${TOKEN}',
		}"
	fi

	pa.sh -e "class { 'hpucho::web': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}.uchoweb' }"
fi

