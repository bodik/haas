#!/bin/sh
# will register sensor at warden server

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -c WARDEN_CA_URL -n CLIENT_NAME -d DESTDIR" 1>&2; exit 1; }
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


#if file exist, sensor is already registred
if [ -f "${DESTDIR}/registered-at-warden-server" ]; then exit 0; fi

URL="${WARDEN_CA_URL}/register_sensor?client_name=${CLIENT_NAME}"
curl --silent --write-out '%{http_code}' "${URL}" | grep 200 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	echo "$URL" > ${DESTDIR}/registered-at-warden-server
	exit 0
else
	echo "ERROR: cannt register at warden server"
	exit 1
fi
