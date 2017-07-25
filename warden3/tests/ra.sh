#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array="apache2" -c 1:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_ra apache check_procs"
fi

netstat -nlpa | grep " $(pgrep -f /usr/sbin/apache2)/apache2" | grep LISTEN | grep ":45446"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden ra http listener"
fi

curl --silent --include "http://$(facter fqdn):45446/warden_ra/getCacert?password=DUMMY" | grep 'BEGIN CERTIFICATE'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden ra http check"
fi

rreturn 0 "$0"
