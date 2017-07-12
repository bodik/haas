#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@


# warden_apply get certificate to /opt/hostcert

find /puppet -name "vm_finalize.sh" -exec /bin/sh {} -w "$WARDEN_SERVER" \;

