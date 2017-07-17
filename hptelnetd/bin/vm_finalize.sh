#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f /opt/telnetd/bin/telnetd.py ]; then
	echo "$WARDEN_SERVER" > /opt/telnetd/bin/registered-at-warden-server
	pa.sh -e "class { 'hptelnetd': warden_server_url => '$WARDEN_SERVER_URL', warden_ca_url => '$WARDEN_CA_URL' }"
fi

