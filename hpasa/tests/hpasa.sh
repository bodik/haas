#!/bin/sh

. /puppet/metalib/bin/lib.sh

TESTID="autotest_$(date +%s)"
python3 $(dirname $(readlink -f $0))/cisco_asa_cve-2018-0101_crash_poc.py "https://localhost:8443" $TESTID
if [ $? -ne 0 ]; then
        rreturn 1 "$0 failed to test ciscoasa_honeypot"
fi

/puppet/warden3/bin/verify_ssl_warden_ra.sh /opt/asa
if [ $? -ne 0 ]; then
        rreturn 1 "$0 racert failed"
fi


rreturn 0 "$0"
