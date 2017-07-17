#!/bin/sh


rreturn() { echo "$2"; exit $1; }

usage() { echo "Usage: $0 -w <WARDEN_SERVER_URL> -c <WARDEN_CA_URL> -t <TOKEN>" 1>&2; exit 1; }
parse_args() {
	while getopts "w:c:t:" o; do
		case "${o}" in
	        	w) WARDEN_SERVER_URL=${OPTARG} ;;
	        	c) WARDEN_CA_URL=${OPTARG} ;;
			t) TOKEN=${OPTARG} ;;
			*) usage ;;
		esac
	done
	shift "$(($OPTIND-1))"

	test -n "$WARDEN_SERVER_URL" || rreturn 1 "ERROR: missing -w WARDEN_SERVER_URL"
	test -n "$WARDEN_CA_URL" || rreturn 1 "ERROR: missing -w WARDEN_CA_URL"
	test -n "$TOKEN" || rreturn 1 "ERROR: missing -t TOKEN"
}

