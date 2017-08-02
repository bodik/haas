#!/usr/bin/python

from warden_client import read_cfg, format_timestamp
from jinja2 import Environment, FileSystemLoader
import SimpleHTTPServer, SocketServer, logging, sys
import json
import os
import sys
import re
import base64
import warden_utils_flab as w3u
import mimetypes

hconfig = read_cfg('uchoweb.cfg')

content_base = os.path.join(os.getcwd(), "content/")
templates_base = os.path.join(os.getcwd(), "templates/")
port = hconfig.get('port', 8081)
personality = hconfig.get('personality', 'Apache Tomcat/7.0.56')

logger = w3u.getLogger(hconfig['logfile'])

class UchowebHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
	server_version = personality
	sys_version = ""

	def do_GET(self):
		self.process_request()
	def do_POST(self):
		self.process_request()
	def process_request(self):
		self._w3log()

		# directory indexes and query string handling 
		if self.path.endswith('/'):
			file_name = self.path+'index.html'
		else:
			file_name = self.path
		file_name = re.sub("^/", "", file_name)
		file_name = re.sub("/", "AAAA", file_name)
		file_name = re.sub("\?", "BBBB", file_name)
	
		#process request
		try:	
			absolute_path = content_base+file_name
			normalized_path = os.path.normpath(absolute_path)
			if not normalized_path.startswith(content_base):
				return self.not_found()

			# directory indexing helper
			if (not os.path.exists(normalized_path)) and (os.path.exists(normalized_path+"AAAAindex.html")):
				self.send_response(302)
				self.send_header("Location", self.path+"/")
				self.end_headers()
				return

			# get output data
			f = open(normalized_path, "rb")
			mime_type = mimetypes.guess_type(normalized_path)[0]
			output = f.read()
			f.close()
		
		except Exception as e:
			return self.not_found()

		# serve output
	        self.send_response(200)
	        self.send_header('Content-type', mime_type)
	        self.end_headers()
        	self.wfile.write(output)
		return

	def not_found(self):
		j2_env = Environment(loader=FileSystemLoader(templates_base), trim_blocks=True)
		output = j2_env.get_template('404').render(path=self.path)
	        self.send_response(404)
	        self.end_headers()
        	self.wfile.write(output)


	def _w3log(self):
		body_len = int(self.headers.getheader('content-length', 0))
		body_data = self.rfile.read(body_len)
		data2log = {
			"detect_time" : format_timestamp(),
			"src_ip"      : self.client_address[0],
			"src_port"    : self.client_address[1],
			"dst_ip"      : self.request.getsockname()[0],
			"dst_port"    : port,
			"proto"       : ["tcp", "http"],
			"data"        : {"requestline": self.requestline, 
			  	         "headers"    : str(self.headers), 
				         "body"       : base64.b64encode(body_data), 
				         "body_len"   : body_len }
		}
		logger.info(json.dumps(data2log))



if __name__=="__main__":
	# python unbuffered output ?
        sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
        sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

	SocketServer.TCPServer.allow_reuse_address = True
	httpd = SocketServer.TCPServer(("", port), UchowebHandler)
	try:
	    httpd.serve_forever()
	except KeyboardInterrupt:
	    pass
	httpd.server_close()

