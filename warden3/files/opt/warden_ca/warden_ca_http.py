#!/usr/bin/python
# -*- coding: UTF-8 -*-

import json
import logging
import netifaces
import os
import re
import shlex
import socket
import subprocess
import sys
import SimpleHTTPServer
import SocketServer
import urllib
from urlparse import urlparse, parse_qs

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(funcName)s() %(message)s')
local_ip_addresses = [netifaces.ifaddresses(iface)[netifaces.AF_INET][0]['addr'] for iface in netifaces.interfaces() if netifaces.AF_INET in netifaces.ifaddresses(iface)]




class ca_handler(SimpleHTTPServer.SimpleHTTPRequestHandler):
	routes = {
		"/get_ca_crt": "get_ca_crt",
		"/get_ca_crl": "get_ca_crl",
		"/get_crt": "get_crt",
		"/put_csr": "put_csr",
		"/register_sensor": "register_sensor",
	}

	def do_GET(self):
		self.process_request()
	def do_POST(self):
		self.process_request()
	def process_request(self):
		if config["same_subnet"] and (not self._same_subnet()):
			self.send_response(403)
			self.end_headers()
			

		uri = urlparse(self.path).path
		try:
			if uri in self.routes.keys():
    				method = getattr(ca_handler, self.routes[uri])
				(code, data) = method(self)
				self.send_response(code)
				self.end_headers()
				if data:
					self.wfile.write(data)
			else:
				self.send_response(404)
				self.end_headers()
	
		except Exception as e:
			logger.error("%s %s %s" % (self.client_address[0], urlparse(self.path), e))
			self.send_error(500)



	def get_ca_crt(self):
                data = subprocess.check_output(shlex.split("/bin/sh warden_ca.sh get_ca_crt"))
		return (200, data)



	def get_ca_crl(self):
                data = subprocess.check_output(shlex.split("/bin/sh warden_ca.sh get_ca_crl"))
		return (200, data)



	def get_crt(self):
		#TODO: validate in case attacker has very nasty PTR
		hostname = self._resolve_client_address(self.client_address[0])
		cmd = "/bin/sh warden_ca.sh get_crt %s" % hostname 
                data = subprocess.check_output(shlex.split(cmd))
		return (200, data)



	def put_csr(self):
		hostname = self._resolve_client_address(self.client_address[0])
		filename = "ssl/ca/requests/%s.pem" % hostname
		length = int(self.headers['Content-Length'])
	        post_data = urllib.unquote(self.rfile.read(length).decode('utf-8'))

		#subseqent calls if we want to reissue certificate for same DN, cloud testing and such...
		try:
			cmd = "/bin/sh warden_ca.sh revoke %s" % hostname 
	               	data = subprocess.check_output(shlex.split(cmd))
			cmd = "/bin/sh warden_ca.sh clean %s" % hostname 
			data = subprocess.check_output(shlex.split(cmd))
		except Exception as e:
			pass
		
		csr_file = open(filename, 'w')
		csr_file.write(post_data)
		csr_file.close()

		if config["autosign"]:
			self._sign(hostname)

		return (200, None)
		



	
	def register_sensor(self):
		if not config["autosign"]:
			return (403, None)

		qs = parse_qs(urlparse(self.path).query)
		if 'sensor_name' not in qs:
			logger.error("parameter sensor_name missing")
			return (400, None)

		hostname = self._resolve_client_address(self.client_address[0])
	
		try:
			cmd = "/usr/bin/python /opt/warden_server/warden_server.py register -n %s -h %s -r bodik@cesnet.cz --read --write --notest" % (qs['sensor_name'][0], hostname)
			logger.debug(cmd)
			data = subprocess.check_output(shlex.split(cmd))
	
		except subprocess.CalledProcessError as e:
			if ( e.returncode == 101 ):
				# client already register, but we accept the state for cloud testing
				logger.warn("client already registerd")
				pass
			else:
				raise e
	
		except Exception as e:
			raise e
	
		return (200, None)



	def _resolve_client_address(self, ip):
		try:
			socket.setdefaulttimeout(5)
			ret = socket.gethostbyaddr(ip)[0]
		except Exception as e:
			logger.warn("%s %s" % (ip, e))
			raise e
		return ret

	def _sign(self, dn):
		logger.warn("autosigning for %s from %s" % (dn, self.client_address[0]))
		cmd = "/bin/sh warden_ca.sh sign %s" % dn
                data = subprocess.check_output(shlex.split(cmd))
		return 0

	def _same_subnet(self):
		if self.client_address[0] in local_ip_addresses:
			return True

		data = subprocess.check_output(shlex.split("ip neigh show")).splitlines()
		for tmp in data:
			#192.168.214.49 dev eth0 lladdr a0:f3:e4:32:86:01 REACHABLE
			pattern = "^%s dev eth0 lladdr ([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}) REACHABLE$" % self.client_address[0]
			if re.match(pattern, tmp):
				return True
		return False



		
class ca_tcpserver(SocketServer.TCPServer):
	def server_bind(self):
        	#import socket
	        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        	self.socket.bind(self.server_address)

if __name__=="__main__":
	# python unbuffered output ?
        sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
        sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

	config = {
		"network_address": "0.0.0.0",
		"listen_port": 45444,
		"same_subnet": True,
		"autosign": True,
		}
	if os.path.exists("warden_ca_http.cfg"):
		config.update(json.loads("warden_ca_http.cfg"))

	httpd = ca_tcpserver((config["network_address"], config["listen_port"]), ca_handler)
	try:
	    httpd.serve_forever()
	except KeyboardInterrupt:
	    pass
	httpd.server_close()

