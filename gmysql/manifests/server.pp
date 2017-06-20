# == Class: gmysql::server
#
# TODO documentation
#
class gmysql::server(
	$mysql_buser = "bckup",
	$mysql_buser_wpass = undef,
 	$mysql_nuser = "nagios",
	$mysql_nuser_wpass = undef,
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	class { '::mysql::server':
		package_name => "mariadb-server",
		service_provider => "debian",
		manage_config_file => false,
		notify => Exec["mysql passwordless accounts"],
	}
	package { "mysqltuner": ensure => installed, }

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


#	file { "/etc/mysql/mariadb.conf.d/90-miscgcm.cnf":
#	        source => "puppet:///modules/${module_name}/etc/mysql/mariadb.conf.d/90-miscgcm.cnf",
#	        owner => "root", group => "root", mode => "0644",
#	        require => Package["mysql-server"],
#		notify => Service["mysqld"],
#	}

	exec { "mysql passwordless accounts":
                command => "/bin/sh /puppet/gmysql/bin/nopass.sh || true",
		require => Package["mysql-server"],
        }



	if ($mysql_buser_wpass) {
	        $mysql_buser_wpass_real = $mysql_buser_wpass
	} else {
	        if ( file_exists("/etc/bacula/scripts/mysql_buser.wpass") == 1 ) {
	                $mysql_buser_wpass_real = myexec("/bin/cat /etc/bacula/scripts/mysql_buser.wpass")
	        } else {
	                $mysql_buser_wpass_real = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
	                notice("INFO: mysql_buser.wpass secret generated")
	        }
	}
	if ($mysql_buser_wpass_real) {
	        file { "/etc/bacula":
	                ensure => "directory",
			owner => "root", group => "root", mode => "0644",
	        }
	        file { "/etc/bacula/scripts":
	                ensure => "directory",
	                require => File["/etc/bacula"],
			owner => "root", group => "root", mode => "0640",
	        }
	        file { "/etc/bacula/scripts/mysql_buser.wpass":
	                content => "$mysql_buser_wpass_real\n",
	                owner => "root", group => "root", mode => "0600",
	                require => File["/etc/bacula/scripts"],
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
	
	        mysql_user { "${mysql_buser}@localhost":
	                ensure => present,
	                password_hash => mysql_password($mysql_buser_wpass_real),
	        }
	        mysql_grant { "${mysql_buser}@localhost/*.*":
	                ensure     => present,
	                privileges => ["SELECT", "LOCK TABLES", "SHOW VIEW", "TRIGGER", "PROCESS", "EVENT", "SUPER"],
	                table      => '*.*',
	                user       => "${mysql_buser}@localhost",
			require => Mysql_user["${mysql_buser}@localhost"],

 	        }

	} else {
	        warning("SKIPPED mysql bacula backup scripts facts missing")
	}



	if ($mysql_nuser_wpass) {
	        $mysql_nuser_wpass_real = $mysql_nuser_wpass
	} else {
	        if ( file_exists("/etc/mysql/mysql_nuser.wpass") == 1 ) {
	                $mysql_nuser_wpass_real = myexec("/bin/cat /etc/mysql/mysql_nuser.wpass")
	        } else {
	                $mysql_nuser_wpass_real = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
	                notice("INFO: mysql_nuser.wpass secret generated")
	        }
	}
	if ($mysql_nuser_wpass_real) {
	        file { "/etc/mysql/mysql_nuser.wpass":
	                content => "$mysql_nuser_wpass_real\n",
	                owner => "root", group => "root", mode => "0600",
	        }
	        mysql_user { "${mysql_nuser}@localhost":
	                ensure => present,
	                password_hash => mysql_password($mysql_nuser_wpass_real),
	        }
        	mysql_grant { "${mysql_nuser}@localhost/*.*":
	                ensure     => present,
	                privileges => ["USAGE"],
	                table      => '*.*',
	                user       => "${mysql_nuser}@localhost",
			require => Mysql_user["${mysql_nuser}@localhost"],
	        }
	} else {
	        warning("SKIPPED mysql nagios facts missing")
	}


	cron { "mysql passwordless accounts":
                command => "/bin/sh /puppet/gmysql/bin/nopass.sh",
                user => root,
                hour => 0,
                minute => 1,
        }

}

