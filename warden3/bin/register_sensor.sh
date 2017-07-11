#!/bin/sh
# will register sensor at warden server

CA_SERVICE="http://${WARDEN_SERVER}:45444"


rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -s <WARDEN_SERVER> -n <SENSOR_NAME> -d <DESTDIR>" 1>&2; exit 1; }
while getopts "s:n:d:" o; do
	case "${o}" in
        	s) WARDEN_SERVER=${OPTARG} ;;
	        n) SENSOR_NAME=${OPTARG} ;;
		d) DESTDIR=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$WARDEN_SERVER" || rreturn 1 "ERROR: missing WARDEN_SERVER"
test -n "$SENSOR_NAME" || rreturn 1 "ERROR: missing SENSOR_NAME"
test -n "$DESTDIR" || rreturn 1 "ERROR: missing DESTDIR"



#if tagfile exist, a sensor is probably already registred, this is just puppet helper conditional
test -f "${DESTDIR}/registered-at-warden-server" || exit 0


URL="${CA_SERVICE}/register_sensor?sensor_name=${SENSOR_NAME}"
curl --silent --write-out '%{http_code}' "${URL}" | grep 200 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	echo "$URL" > ${DESTDIR}/registered-at-warden-server
	exit 0
else
	echo "ERROR: cannt register at warden server"
	exit 1
fi

