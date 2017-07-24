# Installs Dionaea honeypot
#
# @example Declaring the class
#   class { "hpdio": }
#
# @param install_dir Installation directory
# @param service_user User to run service as
# @param log_history The number of days the data is stored on
#
# @param warden_server_url warden server url to connect
# @param warden_ca_url warden ca url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
# @param warden_ca_service avahi name of warden ca service for autodiscovery
class hpdio (
	$install_dir = "/opt/dionaea",

	$service_user = "dionaea",
	$log_history = 14,
	
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
	user { "$service_user":
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "$service_user", group => "$service_user", mode => "0755",
		require => User["$service_user"],
	}

	$packages = ["autoconf", "automake", "build-essential", "check", "cython3", "libcurl4-openssl-dev", "libemu-dev", "libev-dev", "libglib2.0-dev", "libloudmouth1-dev" ,"libnetfilter-queue-dev", "libnl-3-dev", "libpcap-dev", "libssl-dev", "libtool" ,"libudns-dev", "python3", "python3-dev", "python3-yaml", "sqlite3"]
	package { $packages: ensure => installed, }

	exec { "clone dio":
		command => "/usr/bin/git clone https://github.com/DinoTools/dionaea ${install_dir}",
		require => Package[$packages],
		creates => "${install_dir}/LICENSE",
	}
	exec { "build dio":
		command => "/puppet/${module_name}/bin/build.sh ${install_dir}",
		require => Exec["clone dio"],
	}
	file { "${install_dir}/etc/dionaea/services-enabled":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/epmap.yaml":
  		ensure => link,	target => "${install_dir}/etc/dionaea/services-available/epmap.yaml",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/ftp.yaml":
  		ensure => link,	target => "${install_dir}/etc/dionaea/services-available/ftp.yaml",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/mysql.yaml":
  		ensure => link,	target => "${install_dir}/etc/dionaea/services-available/mysql.yaml",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/sip.yaml":
  		ensure => link, target => "${install_dir}/etc/dionaea/services-available/sip.yaml",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/smb.yaml":
  		ensure => link,	target => "${install_dir}/etc/dionaea/services-available/smb.yaml",
	}
	file { "${install_dir}/etc/dionaea/services-enabled/tftp.yaml":
  		ensure => link,	target => "${install_dir}/etc/dionaea/services-available/tftp.yaml",
	}

	
	file { "${install_dir}/var":
		owner => "$service_user", group => "$service_user", #nomode
		recurse => true,
		require => Exec["build dio"],
	}
	file { "${install_dir}/etc/dionaea/dionaea.cfg":
		content => template("${module_name}/dionaea.cfg.erb"),
		owner => "root", group => "root", mode => "0755",
		require => Exec["build dio"],
	}
	file { "/etc/systemd/system/dionaea.service":
                content => template("${module_name}/dionaea.service.erb"),
                owner => "root", group => "root", mode => "0644",
		require => Exec["build dio"],
        }
        service { "dionaea":
                enable => true,
                ensure => running,
                require => File["/etc/systemd/system/dionaea.service"],
        }

	
     	file { "/etc/logrotate.d/dionaea":
                content => template("${module_name}/dionaea.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
        }

	##autotest
	package { ["netcat"]: ensure => installed, }



	# warden_client pro kippo (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}.dionaea"	
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}

	#reporting
	file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${service_user}", group => "${service_user}", mode => "0755",
        }
	file { "${install_dir}/warden/warden_sender_dio.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_dio.py",
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised = "yes"
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client_dio.cfg":
		content => template("${module_name}/warden_client_dio.cfg.erb"),
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden_dio":
		content => template("${module_name}/warden_dio.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$service_user"],
	}

	warden3::racert { "${w3c_name}":
		destdir => "${install_dir}/racert",
		Exec["build dio"],
        }
}
