#!/bin/sh 

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array="/opt/uchoudp/uchoudp.py" -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /opt/uchoudp/uchoudp.py check_procs"
fi


AGE=$(ps h -o etimes $(pgrep -f /opt/uchoudp/uchoudp.py))
if [ $AGE -lt 30 ] ; then
	echo "INFO: Uchoudp warming up"
	sleep 30
fi

NOW=$(date +%s)

PORT=$(cat /opt/uchoudp/uchoudp.cfg | grep port_start | awk '{print $2}' | sed 's/,//')
echo "autotest $NOW" | nc -u -q1 $(facter ipaddress) $PORT | grep "autotest $NOW"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 failed to open port_start"
fi

PORT=$(cat /opt/uchoudp/uchoudp.cfg | grep port_end | awk '{print $2}' | sed 's/,//')
echo "autotest $NOW" | nc -u -q1 $(facter ipaddress) $(($PORT-1)) | grep "autotest $NOW"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 failed to open port_end"
fi

rreturn 0 "$0"
