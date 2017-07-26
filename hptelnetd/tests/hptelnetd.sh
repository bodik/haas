#!/bin/sh

. /puppet/metalib/bin/lib.sh

python -c 'print "autotest\nautotest.123456\nid\nexit"' | timeout 2s nc $(facter ipaddress) 63023 | grep 'uid=0'
if [ $? -ne 0 ]; then
        rreturn 1 "$0 failed to login to hptelnetd"
fi

/puppet/warden3/bin/verify_ssl_warden_ra.sh /opt/telnetd
if [ $? -ne 0 ]; then
        rreturn 1 "$0 racert failed"
fi


rreturn 0 "$0"
