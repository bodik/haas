#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array=warden_tologstash.py -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_tologstash.py check_procs"
fi

rreturn 0 "$0"
