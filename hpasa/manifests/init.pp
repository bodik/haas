# Installs wardenized https://github.com/Cymmetria/ciscoasa_honeypot
#
# @example Declaring the class
#   class { "hpasa":
#     warden_server => "warden-test.cesnet.cz",
#   }
#
# @param install_dir Installation directory
# @param service_user User to run service as
#
# @param warden_client_name reporting script warden client name
# @param warden_server_url warden server url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
class hpasa (
	$install_dir = "/opt/asa",
	$service_user = "asa",

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
		$warden_client_name_real = regsubst("cz.cesnet.haas.${hostname}.asa", "-", "", 'G')
        }


	# application

	package { ["python3", "python3-pip", "libcap2-bin"]: ensure => installed, }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python3.5",
		unless => "/sbin/getcap /usr/bin/python3.5 | grep cap_net_bind_service",
		require => [Package["python3"], Package["libcap2-bin"]]
	}
	user { "${service_user}":
                ensure => present,
                managehome => false,
        }
	file { ["${install_dir}"]:
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/log":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => [File["${install_dir}"], User["${service_user}"]],
	}

	exec { "clone ciscoasa_honeypot":
		command => "/usr/bin/git clone https://github.com/bodik/ciscoasa_honeypot ${install_dir}/bin",
		creates => "${install_dir}/bin/requirements.txt",
	}
	exec { "install dependencies":
		command => "/usr/bin/pip3 install -r ${install_dir}/bin/requirements.txt",
		creates => "/usr/local/lib/python3.5/dist-packages/ike-0.1.1.egg-info/PKG-INFO",
		require => [Exec["clone ciscoasa_honeypot"], Package["python3-pip"]],
	}
	exec { "create certificate":
		command => "/bin/sh /puppet/metalib/bin/install_sslselfcert.sh ${install_dir}/asacert; cat ${install_dir}/asacert/* > ${install_dir}/asacert/bundle.pem",
		creates => "${install_dir}/asacert/bundle.pem",
		require => Exec["install dependencies"],
	}

	file { "/etc/systemd/system/asa.service":
		content => template("${module_name}/asa.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Exec["create certificate"],
		notify => Service["asa"]
	}
	service { "asa":
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/asa.service"],
	}





	# warden_client
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => Exec["clone ciscoasa_honeypot"],
	}
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Exec["clone ciscoasa_honeypot"],
	}

        # reporting
	file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "root", group => "root", mode => "0644",
        }
        file { "${install_dir}/warden/warden_sender_asa.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_asa.py",
                owner => "root", group => "root", mode => "0755",
		require => Exec["clone ciscoasa_honeypot"],
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden/warden_client_asa.cfg":
                content => template("${module_name}/warden_client_asa.cfg.erb"),
                owner => "root", group => "root", mode => "0644",
		require => Exec["clone ciscoasa_honeypot"],
        }
        file { "/etc/cron.d/warden_asa":
                content => template("${module_name}/warden_asa.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["${service_user}"],
        }
	file { "/etc/logrotate.d/asa":
		content => template("${module_name}/asa.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
	}

        warden3::racert { "${warden_client_name_real}":
                destdir => "${install_dir}/racert",
                require => File["${install_dir}"],
        }
}
