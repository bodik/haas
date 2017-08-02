#!/bin/sh 

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array="/opt/uchoweb/bin/uchoweb.py" -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /opt/uchotcp/bin/uchoweb.py check_procs"
fi


AGE=$(ps h -o etimes $(pgrep -f /opt/uchoweb/bin/uchoweb.py))
if [ $AGE -lt 30 ] ; then
	echo "INFO: Uchoweb warming up"
	sleep 30
fi


PORT=$(cat /opt/uchoweb/bin/uchoweb.cfg | grep port | awk '{print $2}' | sed 's/,//')
curl -s "http://$(facter ipaddress):${PORT}/manager/html" | grep "Tomcat Version"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 failed to check on uchoweb basic content"
fi


/puppet/warden3/bin/verify_ssl_warden_ra.sh /opt/uchoweb
if [ $? -ne 0 ]; then
        rreturn 1 "$0 racert failed"
fi


rreturn 0 "$0"
