#!/bin/sh

DESTDIR="/opt/hostcert"
NAME=$(facter fqdn)

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -w WARDEN_SERVER -d DESTDIR [-n CLIENT_NAME]" 1>&2; exit 1; }
while getopts "w:d:n:" o; do
	case "${o}" in
        	w) WARDEN_SERVER=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		n) NAME=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_SERVER" || rreturn 1 "ERROR: missing WARDEN_SERVER"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"
CA_SERVICE="http://${WARDEN_SERVER}:45444"



mkdir -p ${DESTDIR}
cd ${DESTDIR} || exit 1
if [ -f ${NAME}.crt ]; then
        echo "WARN: certificate ${NAME}.crt already present in ${DESTDIR}"
	find ${DESTDIR} -ls
	exit 0
fi



echo "INFO: generating ${DESTDIR}/${NAME}.key"
openssl req -newkey rsa:4096 -nodes -keyout "${NAME}.key" -out "${NAME}.csr" -subj "/CN=${NAME}/"

echo "INFO: signing ${NAME}.csr"
#TODO: (in)secure
curl --insecure --fail --data-urlencode @"${NAME}.csr" "${CA_SERVICE}/put_csr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ ${SIGNED} -eq 0 ]; do
	curl --insecure --output "${NAME}.crt" "${CA_SERVICE}/get_crt" 2>/dev/null
	openssl x509 -in "${NAME}.crt" 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for warden_ca to sign the csr"
		rm "${NAME}.crt"
		sleep 1
	fi
done

curl --insecure --output "cachain.pem" "${CA_SERVICE}/get_ca_crt" 2>/dev/null
curl --insecure --output "ca.crl" "${CA_SERVICE}/get_crl" 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating ${NAME} certificate from warden_ca"
