# Installs Cowrie honeypot and warden reporting client
#
# @example Declaring the class
#   class { "hpcowrie": }
#
# @param install_dir Installation directory
# @param cowrie_port Service listen port
# @param service_user User to run service as
# @param cowrie_ssh_version_string SSH version announcement
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
	$version_string = undef,

	$mysql_host = "localhost",
	$mysql_port = 3306,
	$mysql_db = "cowrie",
	$mysql_password = undef,
	
	$warden_client_name = undef,
	$warden_server_url = undef,
	$warden_server_service = "_warden-server._tcp",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	# deps
	class { "gmysql::server": }
	


	$config_file = "${install_dir}/etc/cowrie.cfg"

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



	#mysql 
	mysql_database { "${mysql_db}": ensure => "present", }
	if ( $mysql_password ) {
		$mysql_password_real = $mysql_password
	} else {
		if (file_exists("${config_file}") == 1) {
			$mysql_password_real = myexec("/bin/grep '^password =' ${config_file} | /usr/bin/awk -F'=' '{print \$2}' | sed -e 's/^\s//'")
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
		ensure => present,
		privileges => ["SELECT", "INSERT", "DELETE", "UPDATE"],
		table => "${mysql_db}.*",
		user => "${mysql_db}@localhost",
		require => Mysql_user["${mysql_db}@localhost"],
	}
	exec { "install database":
		command => "/usr/bin/mysql ${mysql_db} < ${install_dir}/docs/sql/mysql.sql",
		#command runs if ret is not 0
		unless => "/usr/bin/test \"$(echo 'select count(*) from tables where TABLE_SCHEMA=\"${mysql_db}\"' | /usr/bin/mysql -Nb information_schema)\" -eq \"$(cat ${install_dir}/docs/sql/mysql.sql | grep 'CREATE TABLE' | wc -l)\" ",
		require => [Exec["cowrie clone"], Mysql_database["${mysql_db}"], Mysql_grant["${mysql_db}@localhost/${mysql_db}.*"]],
	}



	# application
	exec { "cowrie clone":
		command => "/usr/bin/git clone https://github.com/micheloosterhof/cowrie.git ${install_dir}",
		creates => "${install_dir}/INSTALL.md",
	}
	$packages = ["git", "python-virtualenv", "libssl-dev", "libffi-dev", "build-essential", "libpython-dev", "python2.7-minimal", "authbind", "python3-dev", "sudo", "libmariadbclient-dev"]
	package { $packages: ensure => installed, }
	exec { "cowrie build":
		command => "/bin/sh /puppet/hpcowrie/bin/build.sh",
		cwd => "${install_dir}",
		creates => "${install_dir}/cowrie-env/build-finished",
		require => [Package[$packages], Exec["cowrie clone"]]
	}
	user { "$service_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/false",
		home => "${install_dir}",
		require => [Exec["cowrie clone"]],
	}
	$vardirs = ["${install_dir}/var/run", "${install_dir}/var/log/cowrie", "${install_dir}/var/lib/cowrie", "${install_dir}/var/lib/cowrie/downloads", "${install_dir}/var/lib/cowrie/tty"]
	file { $vardirs:
		ensure => directory,
		owner => "$service_user", group => "$service_user", mode => "0755",
		require => [Exec["cowrie build"], User["$service_user"]],
	}
	file { "${install_dir}/etc/userdb.txt":
		source => "puppet:///modules/${module_name}/userdb.txt",
		owner => "root", group => "${service_user}", mode => "0640",
		require => Exec["cowrie clone"],
	}

	$version_strings = [
		"SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2",
		"SSH-1.99-OpenSSH_4.7",
		"SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze2",
		"SSH-2.0-Cisco-1.25",
		"SSH-2.0-OpenSSH_5.5 FIPS",
		"SSH-2.0-OpenSSH_6.6",
		"SSH-2.0-OpenSSH_5.9 FIPS",
		"SSH-2.0-V-ij-eMDESX231d"
	]
	if ( $version_string ) {
		$version_string_real = $version_string
	} else {
		if ( file_exists($config_file) == 1 ) {
			$version_string_real = myexec("/bin/grep '^version =' ${config_file} | /usr/bin/awk -F'= ' '{print \$2}' | sed -e 's/^\s//'")
		} else {
			$version_string_real = $version_strings[ fqdn_rand(size($version_strings), generate_password()) ]
			notice("INFO: cowrie ssh version string generated as '$version_string_real'")
		}
	}
	file { "${config_file}":
		content => template("${module_name}/cowrie.cfg.erb"),
		owner => "root", group => "${service_user}", mode => "0640",
		require => [Exec["cowrie build"], File[$vardirs], File["${install_dir}/etc/userdb.txt"]],
		notify => Service["cowrie"],
	}

	

	# service
	file { "/etc/sudoers.d/cowrie":
		content => "${service_user} ALL=(ALL) NOPASSWD: ${install_dir}/bin/iptables\n",
		owner => "root", group => "root", mode => "0755",
		require => Package["sudo"],
	}
	file { "${install_dir}/bin/iptables":
		content => template("${module_name}/iptables.erb"),
		owner => "root", group => "root", mode => "0755",
		require => Exec["cowrie clone"],
	}
	file { "/etc/systemd/system/cowrie.service":
		content => template("${module_name}/cowrie.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}/bin/iptables"],
	}
	ensure_resource("exec", "systemctl daemon-reload", {"command" => "/bin/systemctl daemon-reload", refreshonly => true})
	service { "cowrie": 
		enable => true,
		ensure => running,
		require => [Exec["install database"], File["${config_file}"], File["/etc/systemd/system/cowrie.service"]],
	}


	# os integration
	service { "fail2ban": }
	file { "/etc/fail2ban/jail.local":
		source => "puppet:///modules/${module_name}/jail.local",
		owner => "root", group => "root", mode => "0644",
		notify => Service["fail2ban"],
	}
	file { "${install_dir}/bin/logrotate-clean.sh":
		source => "puppet:///modules/${module_name}/logrotate-clean.sh",
		owner => "root", group => "root", mode => "0755",
		require => File["${config_file}"],
	}
	file { "/etc/logrotate.d/cowrie":
		content => template("${module_name}/cowrie.logrotate.erb"),
		owner => "root", group => "root", mode => "0644",
	}



	#autotest
	package { ["medusa","sshpass"]: ensure => installed, }

	# warden_client pro kippo/cowrie (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
		require => Exec["cowrie clone"],
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
		require => Exec["cowrie clone"],
	}
}
