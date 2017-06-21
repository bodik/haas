#!/usr/bin/python
# -*- coding: utf-8 -*-

from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, sleep
import pprint
import json
import os
import socket
import sys
import signal

DEFAULT_ACONFIG = 'warden_tologstash.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.tologstash'

pp = pprint.PrettyPrinter(indent=4)



def handler(signum = None, frame = None):
	wclient.logger.info("warden_tologstash shutting down")
	sys.exit(0)

def fetch_and_send(wclient):

	start = time()
	ret = wclient.getEvents(count=1000)
	wclient.logger.info("fetch_and_send: got %i events in %s second" % (len(ret), (time()-start)))
	try:
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.connect( (aconfig['logstash_server'], aconfig['logstash_server_warden_port']) )
		for e in ret:
			sock.sendall(json.dumps(e))
			sock.sendall("\n")
	except Exception as e:
		#print "ERROR: while sending data to rediser", e
		wclient.logger.error("fetch_and_send: sending data to logstash; %s" % e)
	finally:
		sock.shutdown(socket.SHUT_RDWR)
		sock.close()
	
	return len(ret)



if __name__ == "__main__":
	signal.signal(signal.SIGTERM , handler)

	aconfig = read_cfg(DEFAULT_ACONFIG)
	wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
	aname = aconfig.get('name', DEFAULT_NAME)
	wconfig['name'] = aname
	wclient = Client(**wconfig)

	while True:
		try:
			#fetch until queue drain and have a rest for while
			while (fetch_and_send(wclient) != 0):
				pass
			sleep(60)
		except KeyboardInterrupt as e:
			break
		except Exception as e:
			wclient.logger.error("%s" % e)
			#backoff
			sleep(1)
			pass

