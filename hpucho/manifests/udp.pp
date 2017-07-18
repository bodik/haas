# Installs ucho udp service
#
# @example Install service with default warden-server autodiscovery
#   class { "hpucho::udp": }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param port_start lowest port to listen
# @param port_end highest port to listen
# @param port_skip list of ports to skip
#
# @param warden_server_url warden server url to connect
# @param warden_ca_url warden ca url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
# @param warden_ca_service avahi name of warden ca service for autodiscovery
class hpucho::udp (
	$install_dir = "/opt/uchoudp",
	$service_user = "uchoudp",
	$port_start = 1,
	$port_end = 32768,
	$port_skip = "[67, 137, 138, 1433, 5678, 65535]",

        $warden_server_url = undef,
        $warden_ca_url = undef,
        $warden_server_service = "_warden-server._tcp",
        $warden_ca_service = "_warden-server-ca._tcp",
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

        if ($warden_server_url) {
                $warden_server_url_real = $warden_server_url
        } else {
                include metalib::avahi
                $warden_server_url_real = avahi_findservice($warden_server_service)
        }

        if ($warden_ca_url) {
                $warden_ca_url_real = $warden_ca_url
        } else {
                include metalib::avahi
                $warden_ca_url_real = avahi_findservice($warden_ca_service)
        }

	# application

	package { ["python", "python-twisted", "python-scapy", "libcap2-bin"]: ensure => installed, }
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
        file { "${install_dir}/bin/uchoudp.cfg":
                content => template("${module_name}/uchoudp.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/uchoudp.py":
		source => "puppet:///modules/${module_name}/uchoudp/uchoudp.py",
		owner => "root", group => "root", mode => "0755",
		require => [Package["python-twisted", "python-scapy"], Exec["python cap_net"], File["${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/warden_client.py", "${install_dir}/bin/uchoudp.cfg"]],
		notify => Service["uchoudp"],
	}

	file { "/etc/systemd/system/uchoudp.service":
		content => template("${module_name}/uchoudp.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/uchoudp.py"],
		notify => Service["uchoudp"],
	}
	service { "uchoudp": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/uchoudp.service"],
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
        file { "${install_dir}/bin/warden_sender_uchoudp.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchoudp.py",
                owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/bin/warden_client_uchoudp.cfg":
                content => template("${module_name}/warden_client_uchoudp.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin"],
        }
        file { "/etc/cron.d/warden_uchoudp":
                content => template("${module_name}/warden_uchoudp.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["${service_user}"],
        }
	file { "/etc/logrotate.d/uchoudp":
		content => template("${module_name}/uchoudp.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

	warden3::hostcert { "hostcert":
                warden_ca_url => $warden_ca_url_real,
                client_name => "${fqdn}",
        }
	exec { "register uchoudp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -c ${warden_ca_url_real} -n ${w3c_name}.uchoudp -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}


}
