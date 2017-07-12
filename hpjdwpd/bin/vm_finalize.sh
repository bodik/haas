#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

if [ -f /opt/jdwpd/bin/jdwpd.py ]; then
	echo "$WARDEN_SERVER" > /opt/jdwpd/bin/registered-at-warden-server
	pa.sh -e "class { 'hpjdpwd': warden_server => '$WARDEN_SERVER' }"
fi

