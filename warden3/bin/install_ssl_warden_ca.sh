#!/bin/sh

DESTDIR="/opt/careg"

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -c <WARDEN_CA_URL> -n <CLIENT_NAME> -d <DESTDIR>" 1>&2; exit 1; }
while getopts "c:n:d:" o; do
	case "${o}" in
        	c) WARDEN_CA_URL=${OPTARG} ;;
        	n) CLIENT_NAME=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_CA_URL" || rreturn 1 "ERROR: missing WARDEN_CA_URL"
test -n "$CLIENT_NAME" || rreturn 1 "ERROR: missing CLIENT_NAME"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"


mkdir -p ${DESTDIR}
cd ${DESTDIR} || exit 1
if [ -f ${CLIENT_NAME}.crt ]; then
        echo "WARN: certificate ${CLIENT_NAME}.crt already present in ${DESTDIR}"
	find ${DESTDIR} -ls
	exit 0
fi



echo "INFO: generating ${DESTDIR}/${CLIENT_NAME}.key"
openssl req -newkey rsa:4096 -nodes -keyout "${CLIENT_NAME}.key" -out "${CLIENT_NAME}.csr" -subj "/CN=${CLIENT_NAME}/"

echo "INFO: signing ${CLIENT_NAME}.csr"
#TODO: (in)secure
curl --insecure --fail --data-urlencode @"${CLIENT_NAME}.csr" "${WARDEN_CA_URL}/put_csr?client_name=$CLIENT_NAME"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ ${SIGNED} -eq 0 ]; do
	curl --insecure --output "${CLIENT_NAME}.crt" "${WARDEN_CA_URL}/get_crt?client_name=$CLIENT_NAME" 2>/dev/null
	openssl x509 -in "${CLIENT_NAME}.crt" 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for warden_ca to sign the csr"
		rm "${CLIENT_NAME}.crt"
		sleep 1
	fi
done

curl --insecure --output "cachain.pem" "${WARDEN_CA_URL}/get_ca_crt" 2>/dev/null
curl --insecure --output "ca.crl" "${WARDEN_CA_URL}/get_crl" 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating certificate from warden_ca"
