# == Class: gmysql::server
#
# TODO documentation
#
class gmysql::server() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	# install
	class { '::mysql::server':
		package_name => "mariadb-server",
		service_provider => "debian",
		manage_config_file => false,
		notify => Exec["mysql passwordless accounts"],
	}
	package { "mysqltuner": ensure => installed, }


	# hardening
#maria db authenticated by socket
#	mysql_user { [ "root@$hostname", "root@127.0.0.1", "root@::1", "root@localhost", "root@localhost.localdomain"]:
#	        ensure => 'absent',
#	        require => File["/root/.my.cnf"],
#	}
	exec { "revoke proxy":
		command => "/usr/bin/mysql -NBe 'TRUNCATE TABLE mysql.proxies_priv; FLUSH PRIVILEGES;'",
		onlyif => "/usr/bin/mysql -NBe 'SHOW GRANTS FOR \"root\"@\"localhost\"' | /bin/grep PROXY",
		require => Package["mysql-server"],
	}
	exec { "mysql passwordless accounts":
                command => "/bin/sh /puppet/gmysql/bin/nopass.sh || true",
		require => Package["mysql-server"],
        }
	cron { "mysql passwordless accounts":
                command => "/bin/sh /puppet/gmysql/bin/nopass.sh",
                user => root, hour => 0, minute => 1,
        }


	# config
#	file { "/etc/mysql/mariadb.conf.d/90-miscgcm.cnf":
#	        source => "puppet:///modules/${module_name}/etc/mysql/mariadb.conf.d/90-miscgcm.cnf",
#	        owner => "root", group => "root", mode => "0644",
#	        require => Package["mysql-server"],
#		notify => Service["mysqld"],
#	}


	# backup
	file { "/etc/bacula":
		ensure => "directory",
		owner => "root", group => "root", mode => "0644",
	}
	file { "/etc/bacula/scripts":
		ensure => "directory",
	        require => File["/etc/bacula"],
		owner => "root", group => "root", mode => "0640",
	}
	file { "/etc/bacula/scripts/mysql_backup2.sh":
		source => "puppet:///modules/${module_name}/etc/bacula/scripts/mysql_backup2.sh",
		owner => "root", group => "root", mode => "0700",
	        require => File["/etc/bacula/scripts"],
	}
	file { "/etc/bacula/scripts/mysql_backup2_del.sh":
		source => "puppet:///modules/${module_name}/etc/bacula/scripts/mysql_backup2_del.sh",
		owner => "root", group => "root", mode => "0700",
	        require => File["/etc/bacula/scripts"],
	}
}
