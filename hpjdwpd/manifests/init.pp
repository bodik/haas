# Installs jdwp honeypot
#
# @example Declaring the class
#   class { "hpjdwpd":
#     jdwpd_port => 8001,
#     warden_server => "warden-test.cesnet.cz",
#   }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param jdwpd_port Service listen port
#
# @param warden_server_url warden server url to connect
# @param warden_ca_url warden ca url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
# @param warden_ca_service avahi name of warden ca service for autodiscovery
class hpjdwpd (
	$install_dir = "/opt/jdwpd",
	$service_user = "jdwpd",
	$jdwpd_port = 8000,
	
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
		require => File["${install_dir}/bin", "${install_dir}/bin/warden_utils_flab.py", "${install_dir}/bin/warden_client.py", "${install_dir}/bin/jdwpd.cfg"],
		notify => Service["jdwpd"],
	}

	file { "/etc/systemd/system/jdwpd.service":
		content => template("${module_name}/jdwpd.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/jdwpd.py"],
		notify => Service["jdwpd"],
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
	$w3c_name = "cz.cesnet.flab.${hostname}.jdwpd"
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
                owner => "root", group => "root", mode => "0644",
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

	warden3::racert { "${w3c_name}":
		destdir => "${install_dir}/racert"
	}
}
