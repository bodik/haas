#!/bin/sh

INSTALL_DIR=/opt/telnetd

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f ${INSTALL_DIR}/bin/telnetd.py ]; then

	if [ -z "${AUTOTEST}" ]; then
		/puppet/jenkins/bin/haas_finalize_racert.sh -i $INSTALL_DIR $@
	fi
	pa.sh -e "class { 'hptelnetd': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}' }"
fi

