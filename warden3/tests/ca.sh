#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array="/opt/warden_ca/warden_ca_http.py" -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /opt/warden_ca/warden_ca_http.py check_procs"
fi

netstat -nlpa | grep " $(pgrep -f /opt/warden_ca/warden_ca_http.py)/python" | grep LISTEN | grep ":45444"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_ca_http listener"
fi

curl --silent --include "http://$(facter fqdn):45444/get_ca_crt" | grep 'BEGIN CERTIFICATE'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_ca_http check"
fi

