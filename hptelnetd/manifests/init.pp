#!/usr/bin/puppet apply

class hptelnetd (
	$install_dir = "/opt/telnetd",

	$telnetd_user = "telnetd",
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
	user { "$telnetd_user": 	
		ensure => present, 
		managehome => false,
	}
	file { "${install_dir}":
		ensure => directory,
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => User["$telnetd_user"],
	}
	file { "${install_dir}/commands":
		ensure => directory,
		source => "puppet:///modules/${module_name}/commands/",
		purge => true, recurse => true,
                owner => "$telnetd_user", group => "$telnetd_user", mode => "0644",
                require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${telnetd_user}", group => "${telnetd_user}", mode => "0755",
                require => File["${install_dir}"],
        }
    	file { "${install_dir}/telnetd.cfg":
                content => template("${module_name}/telnetd.cfg.erb"),
                owner => "$telnetd_user", group => "$telnetd_user", mode => "0644",
                require => File["${install_dir}"],
        }
	file { "${install_dir}/telnetd.py":
		source => "puppet:///modules/${module_name}/telnetd.py",
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => File["${install_dir}/commands", "${install_dir}/warden_utils_flab.py", "${install_dir}/telnetd.cfg"],
	}


    	file { "/opt/telnetd-iptables":
                content => template("${module_name}/telnetd-iptables.erb"),
                owner => "root", group => "root", mode => "0755",
        }
	file { "/etc/sudoers.d/telnetd":
		content => "${telnetd_user} ALL=(ALL) NOPASSWD: /opt/telnetd-iptables\n",
		owner => "root", group => "root", mode => "0755",
		require => [Package["sudo"], File["/opt/telnetd-iptables"]],
	}
	file { "/etc/systemd/system/telnetd.service":
		content => template("${module_name}/telnetd.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/telnetd.py", "/etc/sudoers.d/telnetd"],
	}
	service { "telnetd": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/telnetd.service"],
	}



	#autotest
	package { ["netcat"]: ensure => installed, }



	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0640",
		require => File["${install_dir}"],
	}

	# reporting
	file { "${install_dir}/warden_sender_telnetd.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_telnetd.py",
                owner => "${telnetd_user}", group => "${telnetd_user}", mode => "0755",
        	require => File["${install_dir}/warden_utils_flab.py"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
   	file { "${install_dir}/warden_client_telnetd.cfg":
                content => template("${module_name}/warden_client_telnetd.cfg.erb"),
                owner => "$telnetd_user", group => "$telnetd_user", mode => "0644",
                require => File["${install_dir}/telnetd.py", "${install_dir}/warden_sender_telnetd.py"],
        }
    	file { "/etc/cron.d/warden_telnetd":
                content => template("${module_name}/warden_telnetd.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$telnetd_user"],
        }

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register telnetd sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.telnetd -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}
}
