#!/bin/sh


rreturn() { echo "$2"; exit $1; }

parse_args() {
	while getopts "w:s:t:" o; do
		case "${o}" in
	        	w) WARDEN_SERVER=${OPTARG} ;;
		        s) SECRET=${OPTARG} ;;
			t) TOKEN=${OPTARG} ;;
			*) usage ;;
		esac
	done
	shift "$(($OPTIND-1))"
	
	test -n "$WARDEN_SERVER" || rreturn 1 "ERROR: missing -w WARDEN_SERVER"
	test -n "$SECRET" || rreturn 1 "ERROR: missing -s SECRET"
}

