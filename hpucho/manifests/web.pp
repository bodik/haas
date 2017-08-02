# Installs ucho web service and warden reporting client
#
# @example Install service with default warden-server autodiscovery
#   class { "hpucho::web": }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param port port to listen
# @param personality webserver identification
# @param content content file
#
# @param warden_client_name reporting script warden client name
# @param warden_server_url warden server url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
class hpucho::web (
	$install_dir = "/opt/uchoweb",
	$service_user = "uchoweb",
	$port = 8080,
	$personality = "Apache Tomcat/7.0.56 (Debian)",
	$content = "content.tgz",

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
		$warden_client_name_real = regsubst("cz.cesnet.haas.${hostname}.uchoweb", "-", "", 'G')
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
		command => "/bin/tar xzf /puppet/hpucho/files/uchoweb/${content}",
		cwd => "${install_dir}/bin/",
		creates => "${install_dir}/bin/content",
	}


	file { "/etc/systemd/system/uchoweb.service":
		content => template("${module_name}/uchoweb.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/uchoweb.py"],
		notify => Service["uchoweb"]
	}
	service { "uchoweb": 
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/uchoweb.service"],
	}



	#autotest
	package { ["netcat"]: ensure => installed, }



	# warden_client
	file { "${install_dir}/bin/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
	}
	file { "${install_dir}/bin/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin"],
	}

        # reporting
        file { "${install_dir}/bin/warden_sender_uchoweb.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchoweb.py",
                owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/bin"],
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/bin/warden_client_uchoweb.cfg":
                content => template("${module_name}/warden_client_uchoweb.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin"],
        }
        file { "/etc/cron.d/warden_uchoweb":
                content => template("${module_name}/warden_uchoweb.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["${service_user}"],
        }
	file { "/etc/logrotate.d/uchoweb":
		content => template("${module_name}/uchoweb.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

        warden3::racert { "${warden_client_name_real}":
                destdir => "${install_dir}/racert",
                require => File["${install_dir}"],
        }
}
