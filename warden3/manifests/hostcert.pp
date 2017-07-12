# == Resource: warden3::hostcert
#
# Resource will ensure provisioning of SSL certificated used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ca service located on warden server. Formelly class 
# truned into reusable resource.
#
# TODO: allow changing ca service port
#
# === Parameters
#
# [*destdir*]
#   directory to generate certificate
#
# [*warden_server*]
#   name or ip of warden server, overrides autodiscovery
#
# [*warden_server_service*]
#   service name to be discovered
#
define warden3::hostcert (
	$destdir = "/opt/hostcert",

        $warden_server = undef,
        $warden_server_service = "_warden-server._tcp",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")
	#notice("INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include ${name}\"")

        if ($warden_server) {
                $warden_server_real = $warden_server
        } else {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }
	
	ensure_resource( 'package', 'curl', {} )
	ensure_resource( 'file', "$destdir", { "ensure" => directory, "owner" => "root", "group" => "root", "mode" => "0755",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -w ${warden_server_real} -d ${destdir}",
		creates => "${destdir}/${fqdn}.crt",
		require => [File["$destdir"], Package["curl"]],
	}
}
