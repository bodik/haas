# == Class: warden3::server
#
# Class will ensure installation of warden3 server: apache2, wsgi, server, mysqldb, configuration
#
# === Parameters
#
# [*install_dir*]
#   directory to install w3 server
#
# [*port*]
#   port number to listen with apache vhost
#
# [*mysql_... *]
#   parameters for mysql database for w3 server
#
# [*avahi_enable*]
#   enable service announcement, enabled by default. for testing and debugging purposes
#
class warden3::server (
	$install_dir = "/opt/warden_server",
	$service_port = 45443,

	$mysql_host = "localhost",
	$mysql_port = 3306,
        $mysql_db = "warden3",
        $mysql_password = false,

	$avahi_enable = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	if ($avahi_enable) {
		include metalib::avahi
	        file { "/etc/avahi/services/warden-server.service":
	                content => template("${module_name}/warden_server.avahi-service.erb"),
	                owner => "root", group => "root", mode => "0644",
	                require => Package["avahi-daemon"],
	                notify => Service["avahi-daemon"],
	        }
	}

	#mysql server
	# mysql replaced by gmysql component
	class { "gmysql::server": }



	#warden3

	#datastore
        if( $mysql_db ) {
                mysql_database { "${mysql_db}": ensure => 'present', }

                if ( $mysql_password ) {
                        $mysql_password_real = $mysql_password
                } else {
                        if ( file_exists("${install_dir}/warden_server.cfg") == 1 ) {
                                $mysql_password_real = warden_config_dbpassword("${install_dir}/warden_server.cfg")
                                notice("INFO: mysql ${mysql_db}@localhost password preserved")
                        } else {
                                $mysql_password_real = generate_password()
                                notice("INFO: mysql ${mysql_db}@localhost password generated")
                        }
                }
                        
                mysql_user { "${mysql_db}@localhost":
			ensure => present,
			password_hash => mysql_password($mysql_password_real),
                }
                mysql_grant { "${mysql_db}@localhost/${mysql_db}.*":
			ensure => present,
			privileges => ["SELECT", "INSERT", "DELETE", "UPDATE"],
			table => "${mysql_db}.*",
			user => "${mysql_db}@localhost",
			require => Mysql_user["${mysql_db}@localhost"],
                }
        }

	#server application
	package { ["python-mysqldb", "python-m2crypto", "python-pip", "python-jsonschema"]: ensure => installed, }

	file { "$install_dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	$sources = "puppet:///modules/${module_name}/opt/warden_server"
	file { "${install_dir}/warden_server.wsgi":
		source => "${sources}/warden_server.wsgi.dist",
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/warden_server.py":
		source => "${sources}/warden_server.py",
		owner => "root", group => "root", mode => "0755",
		notify => Service["apache2"],
	}
	file { "${install_dir}/catmap_mysql.json":
		source => "${sources}/catmap_mysql.json",
		owner => "root", group => "root", mode => "0644",
	}
	file { "${install_dir}/tagmap_mysql.json":
		source => "${sources}/tagmap_mysql.json",
		owner => "root", group => "root", mode => "0644",
	}
	file { "${install_dir}/idea.schema":
		source => "${sources}/idea.schema",
		owner => "root", group => "root", mode => "0644",
	}

        exec { "create warden database":
                command => "/usr/bin/mysql -NB ${mysql_db} < /puppet/${module_name}/files/opt/warden_server/warden_3.0.sql",
                unless => "/usr/bin/mysql -NBe 'describe last_events' ${mysql_db} | grep timestamp",
                require => Mysql_database["${mysql_db}"],
        }


	file { "${install_dir}/warden_server.cfg":
		content => template("${module_name}/warden_server.cfg.erb"),
		owner => "root", group => "www-data", mode => "0640",
	}



	#apache2
	ensure_resource('package', 'apache2', {})
	ensure_resource('service', 'apache2', {})
	package { ["libapache2-mod-wsgi"]: ensure => installed, }

        ensure_resource( 'lamp::apache2::a2dismod', "mpm_event", {} )
        ensure_resource( 'lamp::apache2::a2enmod', "mpm_prefork", { "require" => Lamp::Apache2::A2dismod["mpm_event"]} )
        ensure_resource( 'lamp::apache2::a2dismod', "cgid", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "ssl", {} )

	warden3::racert { "${fqdn}":
                destdir => "${install_dir}/racert",
                require => File["${install_dir}"],
        }

	file { "/etc/apache2/sites-enabled/20warden3.conf":
		content => template("${module_name}/warden_server-virtualhost.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [
			Package["apache2", "libapache2-mod-wsgi"], 
			Warden3::Racert["${fqdn}"],
			Lamp::Apache2::A2enmod["ssl"]
			],
		notify => Service["apache2"],
	}

	#tests
	ensure_resource('package', 'curl', {} )
}


