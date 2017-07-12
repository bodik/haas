#!/bin/sh

if [ -f /opt/cowrie/INSTALL.md ]; then
        echo "INFO: CHECK HPCOWRIE ==================="
        pa.sh -v --noop --show_diff -e "include hpcowrie"
fi

