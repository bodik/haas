#!/bin/sh

if [ -f /opt/cowrie/bin/cowrie ]; then
        echo "INFO: CHECK HPCOWRIE ==================="
        pa.sh -v --noop --show_diff -e "include hpcowrie"
fi
