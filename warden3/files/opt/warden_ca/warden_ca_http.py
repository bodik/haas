#!/usr/bin/python
# -*- coding: UTF-8 -*-

import json
import logging
import os
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
		csr_file.flush()
		csr_file.close()

		# TODO: self.client_address[0] in same subnet 
		same_subnet = True
		if same_subnet and os.path.exists("AUTOSIGN"):
			self._sign(hostname)
	
		return (200, None)




	
	def register_sensor(self):
		if os.path.exists("AUTOSIGN") == False:
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



		
class ca_tcpserver(SocketServer.TCPServer):
	def server_bind(self):
        	#import socket
	        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        	self.socket.bind(self.server_address)

if __name__=="__main__":
	# python unbuffered output ?
        sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
        sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

	httpd = ca_tcpserver(('0.0.0.0', 45444), ca_handler)
	try:
	    httpd.serve_forever()
	except KeyboardInterrupt:
	    pass
	httpd.server_close()

