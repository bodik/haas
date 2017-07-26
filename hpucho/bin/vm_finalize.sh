#!/bin/sh


. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

INSTALL_DIR=/opt/uchotcp
if [ -f ${INSTALL_DIR}/bin/uchotcp.py ]; then
	if [ -z "${AUTOTEST}" ]; then
		/puppet/jenkins/bin/haas_finalize_racert.sh -i $INSTALL_DIR -w $WARDEN_SERVER_URL -n "${CLIENT_NAME}.uchotcp"
	fi
	pa.sh -e "class { 'hpucho::tcp': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}.uchotcp' }"
fi

INSTALL_DIR=/opt/uchoudp
if [ -f ${INSTALL_DIR}/bin/uchoudp.py ]; then
	if [ -z "${AUTOTEST}" ]; then
		/puppet/jenkins/bin/haas_finalize_racert.sh -i $INSTALL_DIR -w $WARDEN_SERVER_URL -n "${CLIENT_NAME}.uchoudp"
	fi
	pa.sh -e "class { 'hpucho::tcp': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}.uchoudp' }"
fi

