
pa.sh -e 'include warden3::ca'
pa.sh -e 'include warden3::server'

/bin/sh /puppet/warden3/bin/register_sensor.sh -s $(facter fqdn) -n "cz.cesnet.flab.$(facter hostname).puppet_test_client" -d /opt/warden_server
