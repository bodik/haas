#!/usr/bin/python
# -*- coding: utf-8 -*-
#
from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import json
import string
import os
import sys
import warden_utils_flab as w3u

aconfig = read_cfg('warden_client_asa.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'
wclient = Client(**wconfig)

def gen_event_idea_asa(detect_time, src_ip, src_port, dst_ip, dst_port, proto, category, data):

        event = {
                "Format": "IDEA0",
                "ID": str(uuid4()),
                "DetectTime": detect_time,
                "Category": [category],
                "Note": "asa event",
                "ConnCount": 1,
                "Source": [{ "Proto": [proto], "Port": [src_port] }], 
                "Target": [{ "Proto": [proto], "Port": [dst_port] }],
                "Node": [
                        { 
                                "Name": aclient_name,
                                "Tags": ["Honeypot", "Connection"],
                                "SW": ["asa"],
                        }
                ],      
                "Attach": [{ "data": data, "datalen": len(data) }]
        }

	event["Attach"][0]["smart"] = data

        event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)

        return event


events = []
try:
	for line in w3u.Pygtail(filename=aconfig.get('logfile'), wait_timeout=0):
		raw = line.split()
		log_time = raw.pop(0)
		log_loggername = raw.pop(0)
		log_level = raw.pop(0)
		data = json.loads("".join(raw))

		a = gen_event_idea_asa(
			detect_time = log_time, 
			src_ip      = data['src'],
			src_port    = data['spt'], 
			dst_ip      = "0.0.0.0",
			dst_port    = 443,
			proto       = "tcp",
			category    = "Attempt.Exploit",
			data        = line
		)
		#wclient.logger.debug(json.dumps(events))
		events.append(a)
except Exception as e:
	wclient.logger.error(e)
	pass

wclient.logger.debug(json.dumps(events, indent=3))

start = time()
ret = wclient.sendEvents(events)
if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered in %d seconds" % (ret['saved'], (time() - start)))
