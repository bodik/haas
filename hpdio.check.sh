#!/bin/sh

if [ -f /opt/dionaea/bin/dionaea ]; then
        echo "INFO: CHECK HPDIO ======================="
        pa.sh -v --noop --show_diff -e "include hpdio"
fi
