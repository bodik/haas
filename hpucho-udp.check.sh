#!/bin/sh

if [ -f /opt/uchoudp/bin/uchoudp.py ]; then
        echo "INFO: CHECK HPUCHOUDP ================="
        pa.sh -v --noop --show_diff -e "include hpucho::udp"
fi
