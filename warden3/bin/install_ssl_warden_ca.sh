#!/bin/sh

DESTDIR="/opt/hostcert"
FQDN=$(facter fqdn)

usage() { echo "Usage: $0 -w <WARDEN_SERVER> -d <DESTDIR>" 1>&2; exit 1; }
while getopts "w:d:" o; do
	case "${o}" in
        	w) WARDEN_SERVER=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
CA_SERVICE="http://${WARDEN_SERVER}:45444"



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
curl --insecure --fail --data-urlencode @"${FQDN}.csr" "${CA_SERVICE}/put_csr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ ${SIGNED} -eq 0 ]; do
	curl --insecure --output "${FQDN}.crt" "${CA_SERVICE}/get_crt" 2>/dev/null
	openssl x509 -in "${FQDN}.crt" 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for warden_ca to sign the csr"
		rm "${FQDN}.crt"
		sleep 1
	fi
done

curl --insecure --output "cachain.pem" "${CA_SERVICE}/get_ca_crt" 2>/dev/null
curl --insecure --output "ca.crl" "${CA_SERVICE}/get_crl" 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating certificate from warden_ca"

