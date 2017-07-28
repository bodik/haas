#!/bin/sh

INSTALL_DIR=/opt/jdwpd

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f ${INSTALL_DIR}/bin/jdwpd.py ]; then

	if [ -z "${AUTOTEST}" ]; then
		/puppet/jenkins/bin/haas_vm_finalize_racert.sh -i $INSTALL_DIR $@
	fi
	pa.sh -e "class { 'hpjdpwd': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}' }"
fi

