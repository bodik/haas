# Installs Cowrie honeypot and warden reporting client
#
# @example Declaring the class
#   class { "hpcowrie": }
#
# @param install_dir Installation directory
# @param cowrie_port Service listen port
# @param service_user User to run service as
# @param cowrie_ssh_version_string SSH version announcement
# @param log_history The number of days the data is stored on
#
# @param mysql_host MySQL server with Cowrie database to connect
# @param mysql_port Port of MySQL server to connect
# @param mysql_db Database to store Cowrie data
# @param mysql_password Password to MySQL server authtentication
#
# @param warden_client_name reporting script warden client name
# @param warden_server_url warden server url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
class hpcowrie (
	$install_dir = "/opt/cowrie",
	
	$cowrie_port = 45356,
	$service_user = "cowrie",
	$cowrie_ssh_version_string = undef,
	$log_history = 14,

	$mysql_host = "localhost",
	$mysql_port = 3306,
	$mysql_db = "cowrie",
	$mysql_password = undef,
	
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
		$warden_client_name_real = regsubst("cz.cesnet.haas.${hostname}.cowrie", "-", "", 'G')
        }


	#mysql server
	#Replaced by gmysql component 
	class { "gmysql::server": }
	
	#mysql db
        if( $mysql_db) {
                mysql_database { "${mysql_db}":
                        ensure  => 'present',
                }

                if ( $mysql_password ) {
                        $mysql_password_real = $mysql_password
                } else {
                        if ( file_exists("${install_dir}/cowrie.cfg") == 1 ) {
                                $mysql_password_real = myexec("/bin/grep '^password =' ${install_dir}/cowrie.cfg | /usr/bin/awk -F'=' '{print \$2}' | sed -e 's/^\s//'")
                                notice("INFO: mysql ${mysql_db}@localhost password preserved")
                        } else {
                                $mysql_password_real = generate_password()
                                notice("INFO: mysql ${mysql_db}@localhost password generated")
                        }
                }
                        
                mysql_user { "${mysql_db}@localhost":
                                ensure => present,
                                password_hash => mysql_password($mysql_password_real),
				require => Mysql_database["${mysql_db}"],
                }
                mysql_grant { "${mysql_db}@localhost/${mysql_db}.*":
                                ensure     => present,
                                privileges => ["SELECT", "INSERT", "DELETE", "UPDATE"],
                                table      => "${mysql_db}.*",
                                user       => "${mysql_db}@localhost",
                                require => Mysql_user["${mysql_db}@localhost"],
                }
		exec { "install database":
			command => "/usr/bin/mysql ${mysql_db} < ${install_dir}/doc/sql/mysql.sql",
			#command runs if ret is not 0
			unless => "/usr/bin/test \"$(echo 'select count(*) from tables where TABLE_SCHEMA=\"${mysql_db}\"' | /usr/bin/mysql -Nb information_schema)\" -eq \"$(cat ${install_dir}/doc/sql/mysql.sql | grep 'CREATE TABLE' | wc -l)\" ",
			require => [ Mysql_database["${mysql_db}"], Exec["clone cowrie"] ],
		}
        }



	# application
	exec { "clone cowrie":
		command => "/usr/bin/git clone https://github.com/micheloosterhof/cowrie.git ${install_dir}; cd ${install_dir}; git checkout 3d12c8c54b4317dc53baa89c53dbe4bd9480b201",
		creates => "${install_dir}/INSTALL.md",
	} 
	package { ["python-pip", "python-mysqldb", "git", "libmpfr-dev", "libssl-dev", "libmpc-dev", "libffi-dev", "build-essential", "libpython-dev", "python2.7-minimal", "authbind", "sudo"]: 
		ensure => installed, 
	}
	exec { "pip install requirements":
		command => "/usr/bin/pip install -r ${install_dir}/requirements.txt",
		require => Package["python-pip"],
	} 
	user { "$service_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/false",
		home => "${install_dir}",
		require => [Exec["clone cowrie"]],
	}
	file { ["${install_dir}/dl", "${install_dir}/dl/tty", "${install_dir}/data", "${install_dir}/log", "${install_dir}/log/tty", "${install_dir}/var/run", "${install_dir}/etc/", "/opt/cowrie/twisted/plugins/"]:
		owner => "$service_user", group => "$service_user", mode => "0755",
		require => [Exec["clone cowrie"], Exec["pip install requirements"], User["$service_user"]],
	}

	$cowrie_ssh_version_strings = [
		"SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2",
		"SSH-1.99-OpenSSH_4.7",
		"SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze2",
		"SSH-2.0-Cisco-1.25",
		"SSH-2.0-OpenSSH_5.5 FIPS",
		"SSH-2.0-OpenSSH_6.6",
		"SSH-2.0-OpenSSH_5.9 FIPS",
		"SSH-2.0-V-ij-eMDESX231d"
	]

        if ( $cowrie_ssh_version_string ) {
                $corwie_ssh_version_string_real = $cowrie_ssh_version_string
        } else {
        	if ( file_exists("${install_dir}/cowrie.cfg") == 1 ) {
			$cowrie_ssh_version_string_real = myexec("/bin/grep '^version =' ${install_dir}/cowrie.cfg | /usr/bin/awk -F'= ' '{print \$2}' | sed -e 's/^\s//'")
                } else {
			$cowrie_ssh_version_string_real = $cowrie_ssh_version_strings[ fqdn_rand(size($cowrie_ssh_version_strings), generate_password()) ]
			notice("INFO: cowrie ssh version string generated as '$cowrie_ssh_version_string_real'")
                }
        }

	file { "${install_dir}/cowrie.cfg":
		content => template("${module_name}/cowrie.cfg.erb"),
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => [Exec["clone cowrie"], Exec["pip install requirements"], File["${install_dir}/dl", "${install_dir}/dl/tty", "${install_dir}/data","${install_dir}/log", "${install_dir}/log/tty"]],
		notify => Service["cowrie"],
	}

	file_line { "${install_dir}/bin/cowrie-virtualenv":
		ensure => present, path => "${install_dir}/bin/cowrie",
		match => "^VIRTUALENV_ENABLED=", line => "VIRTUALENV_ENABLED=no",
		require => Exec["clone cowrie"],
		notify => Service["cowrie"],
	}
	file_line { "${install_dir}/bin/cowrie-twistdargs":
		ensure => present, path => "${install_dir}/bin/cowrie",
		match => "^\s+TWISTEDARGS=", line => "TWISTEDARGS=\"\${DAEMONIZE} \${XARGS} --logfile /dev/null --pidfile \${PIDFILE}\"",
		require => Exec["clone cowrie"],
		notify => Service["cowrie"],
	}
	file { "${install_dir}/bin/mysql-clean.sh":
		content => template("${module_name}/mysql-clean.sh.erb"),
                owner => "root", group => "root", mode => "0755",
                require => File["${install_dir}/cowrie.cfg"],
        }
	file { "${install_dir}/bin/iptables":
		content => template("${module_name}/iptables.erb"),
                owner => "root", group => "root", mode => "0755",
                require => File["${install_dir}/cowrie.cfg"],
        }
        file { "/etc/sudoers.d/cowrie":
                content => "${service_user} ALL=(ALL) NOPASSWD: ${install_dir}/bin/iptables\n",
                owner => "root", group => "root", mode => "0755",
                require => [Package["sudo"], File["${install_dir}/bin/iptables"]],
        }
	
	file { "${install_dir}/data/userdb.txt":
		source => "puppet:///modules/${module_name}/userdb.txt",
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}


        file { "/etc/logrotate.d/cowrie":
                content => template("${module_name}/cowrie.logrotate.erb"),
                owner => "root", group => "root", mode => "0644",
        }



	service { "fail2ban": }
	file { "/etc/fail2ban/jail.local":
		source => "puppet:///modules/${module_name}/jail.local",
		owner => "root", group => "root", mode => "0644",
		notify => Service["fail2ban"],
	}
        file { "/etc/systemd/system/cowrie.service":
                content => template("${module_name}/cowrie.service.erb"),
                owner => "root", group => "root", mode => "0644",
        }
	ensure_resource( 'exec', "systemctl daemon-reload", { "command" => '/bin/systemctl daemon-reload', refreshonly => true} )
	service { "cowrie": 
		enable => true,
		ensure => running,
		require => [Exec["systemctl daemon-reload"], File["/etc/systemd/system/cowrie.service"], Exec["install database"], Mysql_grant["${mysql_db}@localhost/${mysql_db}.*"] ],
	}


	#autotest
	package { ["medusa","sshpass"]: ensure => installed, }

	# warden_client pro kippo/cowrie (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}

	#reporting

	file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${$service_user}", group => "${$service_user}", mode => "0755",
        }

	file { "${install_dir}/warden/warden_sender_cowrie.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_cowrie.py",
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client_cowrie.cfg":
		content => template("${module_name}/warden_client_cowrie.cfg.erb"),
		owner => "${service_user}", group => "${service_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden_cowrie":
		content => template("${module_name}/warden_cowrie.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$service_user"],
	}
   
	warden3::racert { "${warden_client_name_real}":
                destdir => "${install_dir}/racert",
                require => Exec["clone cowrie"],
	}
}
