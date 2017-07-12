#!/bin/sh


rreturn() { echo "$2"; exit $1; }

usage() { echo "Usage: $0 -w <WARDEN_SERVER> -t <TOKEN>" 1>&2; exit 1; }
parse_args() {
	while getopts "w:t:" o; do
		case "${o}" in
	        	w) WARDEN_SERVER=${OPTARG} ;;
			t) TOKEN=${OPTARG} ;;
			*) usage ;;
		esac
	done
	shift "$(($OPTIND-1))"

	test -n "$WARDEN_SERVER" || rreturn 1 "ERROR: missing -w WARDEN_SERVER"
	test -n "$TOKEN" || rreturn 1 "ERROR: missing -t TOKEN"
}

