#!/bin/sh 

if [ -f /puppet/hostspecs/PRIVATEFILE_host_$(facter fqdn).pp ]; then
	echo "INFO: /puppet/metalib/bin/pa.sh -v --noop --show_diff /puppet/hostspecs/PRIVATEFILE_host_$(facter fqdn).pp"
	/puppet/metalib/bin/pa.sh -v --noop --show_diff /puppet/hostspecs/PRIVATEFILE_host_$(facter fqdn).pp
else
	for all in $(find . -maxdepth 2 -type f -name "*.check.sh"); do
		sh $all
	done
fi

pa.sh -v --noop --show_diff -e "include metalib::puppet_cleanup"

