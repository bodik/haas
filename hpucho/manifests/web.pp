#!/usr/bin/puppet apply

class hpucho::web (
	$install_dir = "/opt/uchoweb",
	$service_user = "uchoweb",
	$port = 8080,
	$personality = "Apache Tomcat/7.0.56 (Debian)",
	$content = "content-tomcat.tgz",

	$warden_client_name = undef,
        $warden_server_url = undef,
        $warden_server_service = "_warden-server._tcp",
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

        if ($warden_server_url) {
                $warden_server_url_real = $warden_server_url
        } else {
                include metalib::avahi
                $warden_server_url_real = avahi_findservice($warden_server_service)
        }

        if ($warden_client_name) {
                $warden_client_name_real = $warden_client_name
        } else {
		$warden_client_name_real = regsubst("cz.cesnet.haas.${hostname}.uchotcp", "-", "", 'G')
        }

	# application
	package { ["python", "python-jinja2"]: ensure => installed, }
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
		require => [File["${install_dir}"], User["${service_user}"]],
	}

        file { "${install_dir}/bin/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/uchoweb.cfg":
                content => template("${module_name}/uchoweb.cfg.erb"),
                owner => "root", group => "root", mode => "0755",
                require => File["${install_dir}/bin"],
        }
	file { "${install_dir}/bin/uchoweb.py":
		source => "puppet:///modules/${module_name}/uchoweb/uchoweb.py",
		owner => "root", group => "root", mode => "0755",
		require => [Package["python-jinja2"], File["${install_dir}/bin/warden_utils_flab.py"], File["${install_dir}/bin/uchoweb.cfg"]],

		notify => Service["uchoweb"],
	}
	exec { "extract content":
		command => "/bin/tar xzf /puppet/hpucho/files/uchoweb/content-tomcat.tgz",
		cwd => "${install_dir}/bin/",
		creates => "${install_dir}/bin/content",
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


	file { "/etc/init.d/uchoweb":
		content => template("${module_name}/uchoweb.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/uchoweb.py", "${install_dir}/uchoweb.cfg"], Exec["content"], Exec["python cap_net"]],
		notify => [Service["uchoweb"], Exec["systemd_reload"]]
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "uchoweb": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/uchoweb"], Exec["systemd_reload"]]
	}


	#autotest
	package { ["netcat"]: ensure => installed, }




	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0640",
		require => File["${install_dir}"],
	}

        # reporting

        file { "${install_dir}/warden_sender_uchoweb.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchoweb.py",
                owner => "${uchoweb_user}", group => "${uchoweb_user}", mode => "0755",
                require => File["${install_dir}/warden_utils_flab.py"],
        }
 	file { "${install_dir}/${logfile}":
                ensure  => 'present',
                replace => 'no',
                owner => "${uchoweb_user}", group => "${uchoweb_user}", mode => "0644",
                content => "",
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden_client_uchoweb.cfg":
                content => template("${module_name}/warden_client_uchoweb.cfg.erb"),
                owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
                require => File["${install_dir}/uchoweb.py","${install_dir}/warden_utils_flab.py","${install_dir}/warden_sender_uchoweb.py"],
        }
        file { "/etc/cron.d/warden_uchoweb":
                content => template("${module_name}/warden_uchoweb.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$uchoweb_user"],
        }
	
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchoweb sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.uchoweb -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}
}
