# Class will ensure installation of example warden3 testing client. Tester will
# generate ammount of idea messages and sends them to w3 server.
#
# @param install_dir directory to install w3 server
#
# @param warden_client_name reporting script warden client name
# @param warden_server_url warden server url to connect
# @param warden_server_service avahi name of warden server service for autodiscovery
class warden3::tester (
	$install_dir = "/opt/warden_tester",

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
		$warden_client_name_real = regsubst("cz.cesnet.haas.${hostname}.tester", "-", "", 'G')
        }



	# warden_client pro tester
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_tester/warden_client/warden_client.py",
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_tester.cfg":
		content => template("${module_name}/warden_tester.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/tester.py":
		source => "puppet:///modules/${module_name}/opt/warden_tester/tester.py",
		owner => "root", group => "root", mode => "0750",
		require => File["${install_dir}"],
	}

	warden3::racert { "${warden_client_name_real}":
                destdir => "${install_dir}/racert",
                require => File["${install_dir}"],
        }
}
