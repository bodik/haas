#!/bin/sh

. /puppet/jenkins/bin/haas_vm_finalize_lib.sh
parse_args $@

cd ${INSTALL_DIR}/racert || exit 1
find . -type f -delete
echo "$WARDEN_SERVER_URL" > registered-at-warden-server
/puppet/warden3/files/opt/warden_ra/warden_apply.sh "https://warden-hub.cesnet.cz/warden-ra/getCert" ${CLIENT_NAME} ${TOKEN}
ln -sf /etc/ssl/certs/ca-certificates.crt cachain.pem

