#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f /opt/cowrie/bin/cowrie ]; then
	echo "$WARDEN_SERVER" > /opt/cowrie/bin/registered-at-warden-server
	pa.sh -e "class { 'hpcowrie': warden_server_url => '$WARDEN_SERVER_URL', warden_ca_url => '$WARDEN_CA_URL' }"
fi

