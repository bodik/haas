#!/usr/bin/puppet apply

class hpucho::tcp (
	$install_dir = "/opt/uchotcp",

	$uchotcp_user = "uchotcp",
	
	$port_start = 1,
	$port_end = 9999,
	$port_skip = "[22,1433,65535]",

	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",
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
	user { "$uchotcp_user":
                ensure => present,
                managehome => false,
        }
	file { "${install_dir}":
		ensure => directory,
		owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
	}
        file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${uchotcp_user}", group => "${uchotcp_user}", mode => "0755",
		require => File["${install_dir}"],
        }
        file { "${install_dir}/uchotcp.cfg":
                content => template("${module_name}/uchotcp.cfg.erb"),
                owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
                require => File["${install_dir}"],
        }
	file { "${install_dir}/uchotcp.py":
		source => "puppet:///modules/${module_name}/uchotcp/uchotcp.py",
		owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
		require => [Package["python-twisted"], Exec["python cap_net"], File["${install_dir}/warden_utils_flab.py"], File["${install_dir}/uchotcp.cfg"]],
		notify => Service["uchotcp"],
	}

	ensure_resource( 'exec', "systemctl daemon-reload", { "command" => '/bin/systemctl daemon-reload', refreshonly => true} )
	file { "/etc/systemd/system/uchotcp.service":
		content => template("${module_name}/uchotcp.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/uchotcp.py"],
		notify => [Service["uchotcp"], Exec["systemctl daemon-reload"]]
	}
	service { "uchotcp": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/uchotcp.service"],
	}



	#autotest
	package { ["netcat"]: ensure => installed, }



	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0640",
		require => File["${install_dir}"],
	}

        # reporting
        file { "${install_dir}/warden_sender_uchotcp.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchotcp.py",
                owner => "${uchotcp_user}", group => "${uchotcp_user}", mode => "0755",
                require => File["${install_dir}/warden_utils_flab.py"],
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden_client_uchotcp.cfg":
                content => template("${module_name}/warden_client_uchotcp.cfg.erb"),
                owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
                require => File["${install_dir}/uchotcp.py","${install_dir}/warden_utils_flab.py","${install_dir}/warden_sender_uchotcp.py"],
        }
        file { "/etc/cron.d/warden_uchotcp":
                content => template("${module_name}/warden_uchotcp.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$uchotcp_user"],
        }
		
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchotcp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.uchotcp -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
