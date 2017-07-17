# Resource will ensure provisioning of SSL certificated used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ca service located on warden server. Formelly class 
# truned into reusable resource.
#
# @param destdir directory to generate certificate
#
# @param warden_ca_url warden ca url to connect
# @param warden_ca_service avahi name of warden ca service for autodiscovery
define warden3::hostcert (
	$destdir = "/opt/hostcert",

        $warden_ca_url = undef,
        $warden_ca_service = "_warden-server-ca._tcp",
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

        if ($warden_ca_url) {
                $warden_ca_url_real = $warden_server_url
        } else {
                include metalib::avahi
                $warden_ca_url_real = avahi_findservice($warden_ca_service)
        }	

	ensure_resource( 'package', 'curl', {} )
	ensure_resource( 'file', "$destdir", { "ensure" => directory, "owner" => "root", "group" => "root", "mode" => "0755",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -c ${warden_ca_url_real} -d ${destdir}",
		creates => "${destdir}/${fqdn}.crt",
		require => [File["$destdir"], Package["curl"]],
	}
}
