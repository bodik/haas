#!/bin/sh

INSTALL_DIR=/opt/dionaea

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@


if [ -f ${INSTALL_DIR}/bin/dionaea ]; then

       if [ ${AUTOTEST} -eq 0 ]; then
		pa.sh -e "warden3::cert { '${CLIENT_NAME}':
			destdir => '${INSTALL_DIR}/racert',
			token => '${TOKEN}',
		}"
       fi
       pa.sh -e "class { 'hpdio': warden_server_url => '${WARDEN_SERVER_URL}', warden_client_name => '${CLIENT_NAME}' }"
fi
