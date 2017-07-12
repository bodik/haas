#!/bin/sh
# will register sensor at warden server

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -w WARDEN_SERVER -n CLIENT_NAME -d DESTDIR" 1>&2; exit 1; }
while getopts "w:n:d:" o; do
	case "${o}" in
        	w) WARDEN_SERVER=${OPTARG} ;;
	        n) CLIENT_NAME=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_SERVER" || rreturn 1 "ERROR: missing WARDEN_SERVER"
test -n "$CLIENT_NAME" || rreturn 1 "ERROR: missing CLIENT_NAME"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"
CA_SERVICE="http://${WARDEN_SERVER}:45444"



#if file exist, sensor is already registred
if [ -f "${DESTDIR}/registered-at-warden-server" ]; then exit 0; fi

URL="${CA_SERVICE}/register_sensor?client_name=${CLIENT_NAME}"
curl --silent --write-out '%{http_code}' "${URL}" | grep 200 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	echo "$URL" > ${DESTDIR}/registered-at-warden-server
	exit 0
else
	echo "ERROR: cannt register at warden server"
	exit 1
fi
