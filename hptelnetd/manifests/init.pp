#!/usr/bin/puppet apply

class hptelnetd (
	$install_dir = "/opt/telnetd",
	$service_user = "telnetd",
	$telnetd_port = 63023,
	
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
	package { ["python-twisted", "sudo"]: ensure => installed, }
	user { "$service_user": 
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
                require => File["${install_dir}"],
	}

	file { "${install_dir}/bin/commands":
		ensure => directory,
		source => "puppet:///modules/${module_name}/commands/",
		purge => true, recurse => true,
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin"],
	}
	file { "${install_dir}/bin/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "root", group => "root", mode => "0755",
                require => File["${install_dir}/bin"],
        }
    	file { "${install_dir}/bin/telnetd.cfg":
                content => template("${module_name}/telnetd.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/telnetd.py":
		source => "puppet:///modules/${module_name}/telnetd.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin/commands", "${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/telnetd.cfg"],
	}


    	file { "${install_dir}/bin/iptables":
                content => template("${module_name}/iptables.erb"),
                owner => "root", group => "root", mode => "0755",
        }
	file { "/etc/sudoers.d/telnetd":
		content => "${service_user} ALL=(ALL) NOPASSWD: ${install_dir}/bin/iptables\n",
		owner => "root", group => "root", mode => "0755",
		require => [Package["sudo"], File["${install_dir}/bin/iptables"]],
	}
	file { "/etc/systemd/system/telnetd.service":
		content => template("${module_name}/telnetd.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/telnetd.py", "/etc/sudoers.d/telnetd"],
	}
	service { "telnetd": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/telnetd.service"],
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
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}/bin"],
	}

	# reporting
	file { "${install_dir}/bin/warden_sender_telnetd.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_telnetd.py",
                owner => "root", group => "root", mode => "0755",
        	require => File["${install_dir}/bin/warden_utils_flab.py"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
   	file { "${install_dir}/bin/warden_client_telnetd.cfg":
                content => template("${module_name}/warden_client_telnetd.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin/telnetd.py", "${install_dir}/bin/warden_sender_telnetd.py"],
        }
    	file { "/etc/cron.d/warden_telnetd":
                content => template("${module_name}/warden_telnetd.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$service_user"],
        }
	file { "/etc/logrotate.d/telnetd":
		content => template("${module_name}/telnetd.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register telnetd sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.telnetd -d ${install_dir}/bin",
		creates => "${install_dir}/bin/registered-at-warden-server",
		require => File["${install_dir}/bin"],
	}
}
