#!/bin/sh

if [ -f /opt/uchotcp/bin/uchotcp.py ]; then
        echo "INFO: CHECK HPUCHOTCP =================="
        pa.sh -v --noop --show_diff -e "include hpucho::tcp"
fi
