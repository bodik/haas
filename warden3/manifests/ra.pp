# Class will ensure installation of warden3 semi-automated registration and
# certification authority for testing.
#
# @example Usage
#   include warden3::ra
#
# @param install_dir installation directory
# @param service_port port for apache virtualhost
class warden3::ra (
	$install_dir = "/opt/warden_server",
	$service_port = 45446,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	include metalib::avahi
	file { "/etc/avahi/services/warden-ra.service":
		content => template("${module_name}/warden_ra.avahi-service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Package["avahi-daemon"],
		notify => Service["avahi-daemon"],
        }

	# deps
	package { ["python-netifaces", "python-suds"]: ensure => installed }

	# install
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/ejbcaws.py":
		source => "puppet:///modules/${module_name}/opt/warden_ra/ejbcaws.py",
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_server.py":
		source => "puppet:///modules/${module_name}/opt/warden_server/warden_server.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_ra.py":
		source => "puppet:///modules/${module_name}/opt/warden_ra/warden_ra.py",
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}"], File["${install_dir}/warden_server.py"], Package["python-suds", "python-netifaces"],],
	}
	file { "${install_dir}/warden_ra.wsgi":
		source => "puppet:///modules/${module_name}/opt/warden_ra/warden_ra.wsgi",
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_apply.sh":
		source => "puppet:///modules/${module_name}/opt/warden_ra/warden_apply.sh",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_ra.cfg":
		source => "puppet:///modules/${module_name}/opt/warden_ra/warden_ra.cfg",
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/ca":
		ensure => directory,
		owner => "www-data", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/ca/openssl.cnf":
		content => template("${module_name}/warden_ra-openssl.cnf.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/ca"],
	}

	file { "${install_dir}/warden_ra.sh":
		source => "puppet:///modules/${module_name}/opt/warden_ra/warden_ra.sh",
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	exec { "warden_ra.sh init":
		command => "/bin/sh ${install_dir}/warden_ra.sh init",
		cwd => "${install_dir}", user => "www-data",
		creates => "${install_dir}/ca/private/ca.key.pem",
		require => File["${install_dir}/ca/openssl.cnf", "${install_dir}/warden_ra.sh"],
	}


	#apache2
	ensure_resource('package', 'apache2', {})
	ensure_resource('service', 'apache2', {})
	package { ["libapache2-mod-wsgi"]: ensure => installed, }

        ensure_resource( 'lamp::apache2::a2dismod', "mpm_event", {} )
        ensure_resource( 'lamp::apache2::a2enmod', "mpm_prefork", { "require" => Lamp::Apache2::A2dismod["mpm_event"]} )
        ensure_resource( 'lamp::apache2::a2dismod', "cgid", {} )

	file { "/etc/apache2/sites-enabled/10warden3-ra.conf":
		content => template("${module_name}/warden_ra-virtualhost.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2", "libapache2-mod-wsgi"],
		notify => Service["apache2"],
	}
}
