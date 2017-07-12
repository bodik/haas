
pa.sh -e 'include warden3::ca'
pa.sh -e 'include warden3::server'

# exception to register sensor here, it's much easier to make it after wserver running, than requiring all components in manifest
/bin/sh /puppet/warden3/bin/register_sensor.sh -w $(facter fqdn) -n "cz.cesnet.flab.$(facter hostname).puppet_test_client" -d /opt/warden_server

