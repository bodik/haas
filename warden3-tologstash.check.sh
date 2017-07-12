#!/bin/sh

if [ -f /opt/warden_tologstash/warden_tologstash.py ]; then
        echo "INFO: CHECK WARDENTOLOGSTASH============"
        pa.sh -v --noop --show_diff -e "include warden3::tologstash"
fi

