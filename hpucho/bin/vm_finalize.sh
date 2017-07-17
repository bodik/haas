#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f /opt/uchotcp/bin/uchotcp.py ]; then
	echo "$WARDEN_SERVER" > /opt/uchotcp/bin/registered-at-warden-server
	pa.sh -e "class { 'hpucho::tcp': warden_server_url => '$WARDEN_SERVER_URL', warden_ca_url => '$WARDEN_CA_URL' }"
fi

if [ -f /opt/uchoudp/bin/uchodup.py ]; then
	echo "$WARDEN_SERVER" > /opt/uchoudp/bin/registered-at-warden-server
	pa.sh -e "class { 'hpucho::udp': warden_server_url => '$WARDEN_SERVER_URL', warden_ca_url => '$WARDEN_CA_URL' }"
fi
