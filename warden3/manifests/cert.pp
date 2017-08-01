# Resource will ensure provisioning of SSL certificate used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ra/ca service located on warden server
#
# @param destdir directory to generate certificate to
# @param owner destdir owner
# @param group destdir group
# @param warden_ra_url name or ip of warden server, overrides autodiscovery
# @param warden_ra_service service name to be discovered
define warden3::cert (
	$destdir,
	$owner = "root",
	$group = "root",
	$mode = "0755",

        $warden_ra_url = "https://warden-hub.cesnet.cz/warden-ra/getCert",
	$token,
) {
	#notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	ensure_resource( 'package', 'curl', {} )
	ensure_resource( 'file', "$destdir", { "ensure" => directory, "owner" => "${owner}", "group" => "${group}", "mode" => "${mode}",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_cert.sh -r ${warden_ra_url} -n ${name} -d ${destdir} -t ${token}",
		creates => "${destdir}/cert.pem",
		require => [File["$destdir"], Package["curl"]],
	}

	file { "${destdir}/registered-at-warden-server":
		content => "${warden_ra_url}",
		owner => "${owner}", group => "${group}", mode => "${mode}",
	}
}
