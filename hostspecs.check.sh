#!/bin/sh 

if [ -e /puppet/hostspecs/host_$(facter fqdn).pp ]; then
        echo "INFO: HOSTSPECIFICCHECK ======================="
        echo "INFO: pa.sh -v --noop --show_diff /puppet/hostspecs/host_$(facter fqdn).pp"
        pa.sh -v --noop --show_diff /puppet/hostspecs/host_$(facter fqdn).pp
fi

