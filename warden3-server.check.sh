#!/bin/sh

if [ -f /opt/warden_server/warden_server.py ]; then
        echo "INFO: CHECK WARDENSERVER ================"
        pa.sh -v --noop --show_diff -e "include warden3::ca"
        pa.sh -v --noop --show_diff -e "include warden3::server"
fi
