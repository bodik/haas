#!/bin/sh

pa.sh -e "include warden3::ra"
pa.sh -e "include warden3::server"

# exception to register sensor here, it's much easier to make it after wserver running, than requiring all components in manifest
pa.sh -e "warden3::racert { 'cz.cesnet.flab.$(facter hostname).puppet-test-client': destdir => '/opt/warden_server/puppet-test-client' }"

