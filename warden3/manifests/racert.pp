# Resource will ensure provisioning of SSL certificated used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ra/ca service located on warden server
#
# @param destdir directory to generate certificate to
# @param warden_server name or ip of warden server, overrides autodiscovery
# @param warden_server_service service name to be discovered
define warden3::racert (
	$destdir,
	$user = "root",
	$group = "root",

        $warden_server = undef,
        $warden_server_service = "_warden-server._tcp",
) {
	#notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

        if ($warden_server) {
                $warden_server_real = $warden_server
        } else {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }
	
	ensure_resource( 'package', 'curl', {} )
	ensure_resource( 'file', "$destdir", { "ensure" => directory, "owner" => "${user}", "group" => "${group}", "mode" => "0750",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -w ${warden_server_real} -d ${destdir} -n ${name}",
		creates => "${destdir}/${name}.crt",
		require => [File["$destdir"], Package["curl"]],
	}
}
