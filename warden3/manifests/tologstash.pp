# Class will ensure installation of warden3 client which receives new events from server and sends them to logstash
#
# @param install_dir directory to install the component
# @param tologstash_user user to run the service
#
# @param warden_server_url warden server url to connect
# @param warden_ca_url warden ca url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
# @param warden_ca_service avahi name of warden ca service for autodiscovery
class warden3::tologstash (
	$install_dir = "/opt/warden_tologstash",

	$tologstash_user = "tologstash",
	
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
                $warden_ca_url_real = $warden_server_url
        } else {
                include metalib::avahi
                $warden_ca_url_real = avahi_findservice($warden_ca_service)
        }

	# application
	user { "$tologstash_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "${tologstash_user}", group => "${tologstash_user}", mode => "0755",
		require => User["${tologstash_user}"],
	}
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_tologstash/warden_client.py",
		owner => "${tologstash_user}", group => "${tologstash_user}", mode => "0640",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${tologstash_user}", group => "${tologstash_user}", mode => "0640",
		require => File["${install_dir}"],
	}
	ensure_resource('warden3::hostcert', "hostcert", { "warden_server" => $warden_ca_url_real,} )
	exec { "register warden_tologstash sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -c ${warden_ca_url_real} -n ${w3c_name}.tologstash -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

	file { "${install_dir}/warden_tologstash.py":
		source => "puppet:///modules/${module_name}/opt/warden_tologstash/warden_tologstash.py",
		owner => "${tologstash_user}", group => "${tologstash_user}", mode => "0750",
		require => File["${install_dir}"],
		notify => Service["warden_tologstash"],
	}
	file { "${install_dir}/warden_tologstash.cfg":
		content => template("${module_name}/warden_tologstash.cfg.erb"),
		owner => "${tologstash_user}", group => "${tologstash_user}", mode => "0640",
		require => File["${install_dir}"],
		notify => Service["warden_tologstash"],
	}


	file { "/etc/systemd/system/warden_tologstash.service":
		content => template("${module_name}/warden_tologstash.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [
				File[
					"${install_dir}/warden_client.cfg",
					"${install_dir}/warden_tologstash.cfg",
					"${install_dir}/warden_client.py",
					"${install_dir}/warden_tologstash.py"
				], Exec["register warden_tologstash sensor"]],
	}
	service { "warden_tologstash":
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/warden_tologstash.service"],
	}


}
