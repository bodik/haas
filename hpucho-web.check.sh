#!/bin/sh

if [ -f /opt/uchoweb/bin/uchoweb.py ]; then
        echo "INFO: CHECK HPUCHOWEB ================="
        pa.sh -v --noop --show_diff -e "include hpucho::web"
fi
