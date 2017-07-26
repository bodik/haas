#!/bin/sh

. /puppet/metalib/bin/lib.sh

if [ -z "$1" ]; then
	echo "ERROR: missing install dir"
	exit 1
fi
INSTALL_DIR=$1

test -f $INSTALL_DIR/racert/key.pem || rreturn 1 "missing key.pem"
test -f $INSTALL_DIR/racert/csr.pem || rreturn 1 "missing csr.pem"
test -f $INSTALL_DIR/racert/cert.pem || rreturn 1 "missing cert.pem"
test -f $INSTALL_DIR/racert/cachain.pem || rreturn 1 "missing cachain.pem"
test -f $INSTALL_DIR/racert/registered-at-warden-server || rreturn 1 "missing warden server registration flag"

