# == Class: iptables
#
# Class will ensure installation of iptables and iptables-persistent
#
# === Parameters
#
# [*rules_v4*]
#   iptables config file
#
# [*rules_v6*]
#   ip6tables config file
#
# === Examples
#
#   class { "iptables": 
#      irules_v4 => "puppet:///modules/${module_name}/somefile",
#   }
#
class iptables (
	$rules_v4 = "puppet:///modules/${module_name}/nonexistent",
	$rules_v6 = "puppet:///modules/${module_name}/nonexistent",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	package { ["iptables"]: ensure => installed }
	package { "iptables-persistent": ensure => absent,}

	file { ["/var/lib/iptables", "/var/lib/ip6tables"]:
		ensure => "directory",
		owner => "root", group => "root", mode => "0750",
	}


	case $fqdn {
		'somehoney.cesnet..cz':
			{ $rules_v4_real = "puppet:///modules/${module_name}/rules.v4.somehoney" }

		default:	
			{ $rules_v4_real = [ $rules_v4, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4"] }
	}
	case $fqdn {
		'somehoney.cesnet..cz': 	
			{ $rules_v6_real = "puppet:///modules/${module_name}/rules.v6.somehoney" }

		default:
			{ $rules_v6_real = [ $rules_v6, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6"] }
	}


	file { "/var/lib/iptables/active":
		source => $rules_v4_real,
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/iptables"],
		notify => Service["iptables"],
	}
	file { "/var/lib/ip6tables/active":
		source => $rules_v6_real,
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/ip6tables"],
		notify => Service["ip6tables"],
	}
	file { "/var/lib/iptables/inactive":
		source => "puppet:///modules/${module_name}/rules.v4-inactive",
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/iptables"],
		notify => Service["iptables"],
	}
	file { "/var/lib/ip6tables/inactive":
		source => "puppet:///modules/${module_name}/rules.v6-inactive",
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/ip6tables"],
		notify => Service["ip6tables"],
	}


	file { "/etc/init.d/iptables":
		source => "puppet:///modules/${module_name}/etc/init.d/iptables",
		owner => "root", group => "root", mode => "0755",
		notify => Exec["systemd_reload"],
	}
	file { "/etc/init.d/ip6tables":
		source => "puppet:///modules/${module_name}/etc/init.d/ip6tables",
		owner => "root", group => "root", mode => "0755",
		notify => Exec["systemd_reload"],
	}
	ensure_resource( 'exec', "systemd_reload", { "command" => '/bin/systemctl daemon-reload', refreshonly => true} )	
	service { "iptables": 
		ensure => running,
		enable => true, 
		require => [File["/etc/init.d/iptables"], File["/var/lib/iptables/active"], Exec["systemd_reload"]],
	}
	service { "ip6tables": 
		ensure => running,
		enable => true, 
		require => [File["/etc/init.d/ip6tables"], File["/var/lib/ip6tables/active"], Exec["systemd_reload"]],
	}




	file { "/usr/local/bin/sshcrack.pl":
		source => "puppet:///modules/${module_name}/usr/local/bin/sshcrack.pl",
		owner => "root", group => "root", mode => "0755",
	}
	cron { "sshcrack":
		command => "/usr/local/bin/sshcrack.pl",
		user    => root,
		hour    => "*",
		minute  => "*/5"
	}
}
