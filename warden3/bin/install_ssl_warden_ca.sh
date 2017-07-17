#!/bin/sh

DESTDIR="/opt/hostcert"
FQDN=$(facter fqdn)

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -c <WARDEN_CA_URL> -d <DESTDIR>" 1>&2; exit 1; }
while getopts "w:d:" o; do
	case "${o}" in
        	w) WARDEN_CA_URL=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_CA_URL" || rreturn 1 "ERROR: missing WARDEN_CA_URL"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"


mkdir -p ${DESTDIR}
cd ${DESTDIR} || exit 1
if [ -f ${FQDN}.crt ]; then
        echo "WARN: certificate ${FQDN}.crt already present in ${DESTDIR}"
	find ${DESTDIR} -ls
	exit 0
fi



echo "INFO: generating ${DESTDIR}/${FQDN}.key"
openssl req -newkey rsa:4096 -nodes -keyout "${FQDN}.key" -out "${FQDN}.csr" -subj "/CN=${FQDN}/"

echo "INFO: signing ${FQDN}.csr"
#TODO: (in)secure
curl --insecure --fail --data-urlencode @"${FQDN}.csr" "${WARDEN_CA_URL}/put_csr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ ${SIGNED} -eq 0 ]; do
	curl --insecure --output "${FQDN}.crt" "${WARDEN_CA_URL}/get_crt" 2>/dev/null
	openssl x509 -in "${FQDN}.crt" 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for warden_ca to sign the csr"
		rm "${FQDN}.crt"
		sleep 1
	fi
done

curl --insecure --output "cachain.pem" "${WARDEN_CA_URL}/get_ca_crt" 2>/dev/null
curl --insecure --output "ca.crl" "${WARDEN_CA_URL}/get_crl" 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating certificate from warden_ca"
