
pa.sh -e 'include warden3::ca'
pa.sh -e 'include warden3::server'
pa.sh -e 'include warden3::tester'

# exception to register sensor here, it's much easier to make it after wserver running, than requiring all components in manifest
/bin/sh /puppet/warden3/bin/register_sensor.sh -s $(facter fqdn) -n "cz.cesnet.flab.$(facter hostname).puppet_test_client" -d /opt/warden_server

# I bet this solves caveat chicked-egg
# have a clean server >> zero events in db, have a receiving client (tologstash) with not existing warden_client last_event_id file
# so until at least one event comes in, last_events holds 0 for the client and wserver thinks client wants to reset lastReceivedId (getEvents id<=0 block)
# some event comes in from sender, highest event.id becomes > 0
# receiver comes again, with id 0 because of previous 0 items in queue, not that he wants to reset last_received_id, but server resets and receiver misses some of the first messages
if [ $(mysql -NBe 'select count(*) from events;' warden3) -eq 0 ]; then
	python /opt/warden_tester/bootstrap_server.py
fi

