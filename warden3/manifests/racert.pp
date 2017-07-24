# Resource will ensure provisioning of SSL certificated used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ra/ca service located on warden server
#
# @param destdir directory to generate certificate to
# @param owner destdir owner
# @param group destdir group
# @param warden_server name or ip of warden server, overrides autodiscovery
# @param warden_server_service service name to be discovered
define warden3::racert (
	$destdir,
	$owner = "root",
	$group = "root",
	$mode = "0755",

        $warden_ca_url = undef,
        $warden_ca_service = "_warden-server-ca._tcp",
) {
	#notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

        if ($warden_ca_url) {
                $warden_ca_url_real = $warden_ca_url
        } else {
                include metalib::avahi
                $warden_ca_url_real = avahi_findservice($warden_ca_service)
        }
	
	ensure_resource( 'package', 'curl', {} )
	ensure_resource( 'file', "$destdir", { "ensure" => directory, "owner" => "${owner}", "group" => "${group}", "mode" => "${mode}",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -c ${warden_ca_url_real} -n ${name} -d ${destdir}",
		creates => "${destdir}/${name}.crt",
		require => [File["$destdir"], Package["curl"]],
	}

	exec { "register ${name} sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -c ${warden_ca_url_real} -n ${name} -d ${destdir}",
		creates => "${destdir}/registered-at-warden-server",
		require => File["$destdir"],
	}

}
