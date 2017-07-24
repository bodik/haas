# Installs telnetd honeypot
#
# @example Declaring the class
#   class { "hptelnetd": }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param telnetd_port Service listen port
# @param real_telnetd_port Service listen port before redirect
#
# @param warden_server_url warden server url to connect
# @param warden_ca_url warden ca url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
# @param warden_ca_service avahi name of warden ca service for autodiscovery

class hptelnetd (
	$install_dir = "/opt/telnetd",
	$service_user = "telnetd",
	$telnetd_port = 63023,
	$real_telnetd_port = 23,
	
        $warden_server_url = undef,
        $warden_ca_url = undef,
        $warden_server_service = "_warden-server._tcp",
        $warden_ca_service = "_warden-ca._tcp",
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
		require => File["${install_dir}/bin/commands", "${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/warden_client.py", "${install_dir}/bin/telnetd.cfg"],
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
	$w3c_name = "cz.cesnet.flab.${hostname}.telnetd"
	file { "${install_dir}/bin/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0644",
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
	
	warden3::racert { "${w3c_name}":
                destdir => "${install_dir}/racert",
                require => File["${install_dir}"],
        }
}
