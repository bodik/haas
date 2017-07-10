# Installs ucho tcp service
#
# @example Install service with default warden-server autodiscovery
#   class { "hpucho::tcp": }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param port_start lowest port to listen
# @param port_end highest port to listen
# @param port_skip list of ports to skip
#
# @param warden_server warden server hostname
# @param warden_server_auto warden server autodiscovery enable flag
# @param warden_server_service avahi name of warden server service for autodiscovery
class hpucho::tcp (
	String $install_dir = "/opt/uchotcp",
	String $service_user = "uchotcp",
	Integer $port_start = 1,
	Integer $port_end = 9999,
	Array $port_skip = "[22,1433,65535]",

	String $warden_server = undef,
	Boolean $warden_server_auto = true,
	String $warden_server_service = "_warden-server._tcp",
) {

	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }



	# application

	package { ["python", "python-twisted", "libcap2-bin"]: ensure => installed, }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | grep cap_net_bind_service",
		require => [Package["python"], Package["libcap2-bin"]]
	}
	user { "${service_user}":
                ensure => present,
                managehome => false,
        }
	file { ["${install_dir}", "${install_dir}/bin"]:
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/log":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => [File["${install_dir}"], User["${service_user}"]],
	}

        file { "${install_dir}/bin/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
        }
        file { "${install_dir}/bin/uchotcp.cfg":
                content => template("${module_name}/uchotcp.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/uchotcp.py":
		source => "puppet:///modules/${module_name}/uchotcp/uchotcp.py",
		owner => "root", group => "root", mode => "0755",
		require => [Package["python-twisted"], Exec["python cap_net"], File["${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/warden_client.py", "${install_dir}/bin/uchotcp.cfg"]],
		notify => Service["uchotcp"],
	}

	file { "/etc/systemd/system/uchotcp.service":
		content => template("${module_name}/uchotcp.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/uchotcp.py"],
		notify => Service["uchotcp"]
	}
	service { "uchotcp": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/uchotcp.service"],
	}



	#autotest
	package { ["netcat"]: ensure => installed, }



	# warden_client
	file { "${install_dir}/bin/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/bin/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin"],
	}

        # reporting
        file { "${install_dir}/bin/warden_sender_uchotcp.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchotcp.py",
                owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/bin/warden_client_uchotcp.cfg":
                content => template("${module_name}/warden_client_uchotcp.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin"],
        }
        file { "/etc/cron.d/warden_uchotcp":
                content => template("${module_name}/warden_uchotcp.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["${service_user}"],
        }
	file { "/etc/logrotate.d/uchotcp":
		content => template("${module_name}/uchotcp.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchotcp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.uchotcp -d ${install_dir}/bin",
		creates => "${install_dir}/bin/registered-at-warden-server",
		require => File["${install_dir}/bin"],
	}
}
