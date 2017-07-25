#!/bin/sh

DESTDIR="/opt/racert"

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -r <WARDEN_RA_URL> -n <CLIENT_NAME> -d <DESTDIR>" 1>&2; exit 1; }
while getopts "r:n:d:" o; do
	case "${o}" in
        	r) WARDEN_RA_URL=${OPTARG} ;;
        	n) CLIENT_NAME=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_RA_URL" || rreturn 1 "ERROR: missing WARDEN_RA_URL"
test -n "$CLIENT_NAME" || rreturn 1 "ERROR: missing CLIENT_NAME"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"


mkdir -p ${DESTDIR}
cd ${DESTDIR} || exit 1
rm -f key.pem csr.pem cert.pem cachain.pem

TOKEN=$(/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print $1}')
curl "$WARDEN_RA_URL/getToken?name=${CLIENT_NAME}&password=${TOKEN}" 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ra"
	exit 1
fi

bash /puppet/warden3/files/opt/warden_ra/warden_apply.sh ${WARDEN_RA_URL}/getCert ${CLIENT_NAME} ${TOKEN}
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ra"
	exit 1
fi

curl --insecure --output "cachain.pem" "${WARDEN_RA_URL}/getCacert?password=${TOKEN}" 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating certificate from warden_ra"
