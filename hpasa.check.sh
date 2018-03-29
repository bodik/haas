#!/bin/sh

if [ -f /opt/asa/bin/asa_server.py ]; then
        echo "INFO: CHECK HPASA =================="
        pa.sh -v --noop --show_diff -e "include hpasa"
fi
