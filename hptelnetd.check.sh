#!/bin/sh

if [ -f /opt/telnetd/bin/telnetd.py ]; then
        echo "INFO: CHECK HPTELNETD =================="
        pa.sh -v --noop --show_diff -e "include hptelnetd"
fi

