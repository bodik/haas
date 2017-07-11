#!/bin/sh

if [ -f /opt/jdwpd/bin/jdwpd.py ]; then
        echo "INFO: CHECK HPJDWPD ===================="
        pa.sh -v --noop --show_diff -e "include hpjdwpd"
fi
