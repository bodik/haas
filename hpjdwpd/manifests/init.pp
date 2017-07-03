#!/usr/bin/puppet apply

class hpjdwpd (
	$install_dir = "/opt/jdwpd",
	$service_user = "jdwpd",
	$jdwpd_port = 8000,
	
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

	package { ["python-twisted"]: ensure => installed, }	
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
    	file { "${install_dir}/bin/jdwpd.cfg":
                content => template("${module_name}/jdwpd.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
                require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/jdwpd.py":
		source => "puppet:///modules/${module_name}/jdwpd.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin", "${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/jdwpd.cfg"],
	}

	file { "/etc/systemd/system/jdwpd.service":
		content => template("${module_name}/jdwpd.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/jdwpd.py"],
	}
	service { "jdwpd":
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/jdwpd.service"],
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
	file { "${install_dir}/bin/warden_sender_jdwpd.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_jdwpd.py",
                owner => "root", group => "root", mode => "0755",
        	require => File["${install_dir}/bin/warden_utils_flab.py"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
   	file { "${install_dir}/bin/warden_client_jdwpd.cfg":
                content => template("${module_name}/warden_client_jdwpd.cfg.erb"),
                owner => "root", group => "root", mode => "0755",
                require => File["${install_dir}/bin/jdwpd.py", "${install_dir}/bin/warden_sender_jdwpd.py"],
        }
    	file { "/etc/cron.d/warden_jdwpd":
                content => template("${module_name}/warden_jdwpd.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["${service_user}"],
        }
	file { "/etc/logrotate.d/jdwpd":
		content => template("${module_name}/jdwpd.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register jdwpd sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.jdwpd -d ${install_dir}/bin",
		creates => "${install_dir}/bin/registered-at-warden-server",
		require => File["${install_dir}/bin"],
	}
}
