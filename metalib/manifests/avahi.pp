# == Class: metalib::avahi
#
# Class for installling avahi utils and resolving daemon. This class is used
# during dynamic cloud autodiscovery by other classes.
#
# === Examples
#
#  include metalib::avahi
#
class metalib::avahi() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { ["avahi-daemon", "avahi-utils"]:
	        ensure => installed,
	}
	service { "avahi-daemon": 
		ensure => running, 
	}
}
