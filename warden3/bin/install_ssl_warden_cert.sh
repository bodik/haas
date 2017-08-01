#!/bin/sh

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -r <WARDEN_RA_URL> -n <CLIENT_NAME> -d <DESTDIR> -t <TOKEN>" 1>&2; exit 1; }
while getopts "r:n:d:t:" o; do
	case "${o}" in
        	r) WARDEN_RA_URL=${OPTARG} ;;
        	n) CLIENT_NAME=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
        	t) TOKEN=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_RA_URL" || rreturn 1 "ERROR: missing WARDEN_RA_URL"
test -n "$CLIENT_NAME" || rreturn 1 "ERROR: missing CLIENT_NAME"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"
test -n "$TOKEN" || rreturn 1 "ERROR: missing TOKEN"


cd ${DESTDIR} || exit 1
rm -f key.pem csr.pem cert.pem cachain.pem

bash /puppet/warden3/files/opt/warden_ra/warden_apply.sh ${WARDEN_RA_URL}/getCert ${CLIENT_NAME} ${TOKEN}
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ra"
	exit 1
fi

ln -sf /etc/ssl/certs/ca-certificates.crt cachain.pem

echo "INFO: done generating certificate from warden_ra"
