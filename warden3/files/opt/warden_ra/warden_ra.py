#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2016, CESNET, z. s. p. o.
# Use of this source is governed by an ISC license, see LICENSE file.

import sys
import os
import time
import fcntl
import errno
import string
import random
import struct
import operator
import argparse
import json
import logging
import os.path as pth
import subprocess
import shlex
import tempfile
import M2Crypto
import ConfigParser
# *ph* server vulnerable to logjam, local openssl too new, use hammer to disable Diffie-Helmann
import ssl
ssl._DEFAULT_CIPHERS += ":!DH"

import ejbcaws

# usual path to warden server
sys.path.append(pth.join(pth.dirname(__file__), "..", "warden-server"))
import warden_server
from warden_server import Request, ObjectBase, FileLogger, SysLogger, Server, expose, read_cfg

import netifaces
import socket
import re

class ClientDisabledError(Exception): pass
class ClientNotIssuableError(Exception): pass
class AuthenticationError(Exception): pass
class PopenError(Exception): pass


class Client(object):

    def __init__(self, name, admins=None, status=None, pwd=None, opaque=None):
        self.name = name
        self.admins = admins or []
        self.status = status or "New"
        self.pwd = pwd
        self.opaque = opaque or {}

    def update(self, admins=None, status=None, pwd=None):
        if admins is not None:
            self.admins = admins
        if status:
            if self.status == "Disabled" and status not in ("Passive", "Disabled"):
                raise ClientDisabledError("This client is disabled")
            self.status = status
        self.pwd = pwd if status=="Issuable" and pwd else None

    def __str__(self):
        return (
            "Client:   %s\n"
            "Admins:   %s\n"
            "Status:   %s\n"
        ) % (self.name, ", ".join(self.admins), self.status)

    def str(self, verbose=False):
        return str(self) + (str(self.opaque) if self.opaque and verbose else "")


class OpenSSLRegistry(object):

    def __init__(self, log, base_dir,
                 subject_dn_template, openssl_sign, lock_timeout):
        self.base_dir = base_dir
        self.cnf_file = pth.join(base_dir, "openssl.cnf")
        self.client_dir = pth.join(base_dir, "clients")
        self.serial_file = pth.join(base_dir, "serial")
        self.newcerts_dir = pth.join(base_dir, "newcerts")
        self.csr_dir = pth.join(base_dir, "csr")
        self.lock_file = pth.join(base_dir, "lock")
        self.lock_timeout = lock_timeout
        self.log = log
        self.subject_dn_template = subject_dn_template
        self.openssl_sign = openssl_sign
        os.umask(0o0002)    # read privilege for usual apache group

    def get_clients(self):
        return [self.get_client(c) for c in os.listdir(self.client_dir) if pth.isdir(pth.join(self.client_dir, c))]

    def get_client(self, name):
        config = ConfigParser.RawConfigParser()
        try:
            with open(pth.join(self.client_dir, name, "state")) as cf:
                config.readfp(cf)
        except IOError as e:
            if e.errno == errno.ENOENT:
                return None
            raise
        datum = dict(config.items("Client"))
        return Client(name, admins=datum["admins"].split(","), status=datum["status"], pwd=datum.get("password"))

    def new_client(self, name, admins=None):
        user = self.get_client(name)
        if user:
            raise LookupError("Client %s already exists" % name)
        return Client(name, admins)

    def save_client(self, client):
        config = ConfigParser.RawConfigParser()
        config.add_section("Client")
        config.set("Client", "admins", ",".join(client.admins))
        config.set("Client", "status", client.status)
        if client.pwd:
            config.set("Client", "password", client.pwd)
        client_path = pth.join(self.client_dir, client.name)
        try:
            os.makedirs(client_path)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        with tempfile.NamedTemporaryFile(dir=client_path, delete=False) as cf:
            config.write(cf)
        os.chmod(cf.name, 0o660)    # read privilege for usual apache group
        os.rename(cf.name, pth.join(client_path, "state")) # atomic + rewrite, so no need for locking

    def get_certs(self, client):
        files = [fname for fname in os.listdir(pth.join(self.client_dir, client.name)) if not fname.startswith(".") and fname.endswith(".pem")]
        certs = [M2Crypto.X509.load_cert(pth.join(self.client_dir, client.name, fname)) for fname in files]
        return certs

    def __enter__(self):
        self._lockfd = os.open(self.lock_file, os.O_CREAT)
        start = time.time()
        while True:
            try:
                fcntl.flock(self._lockfd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return
            except (OSError, IOError) as e:
                if e.errno != errno.EAGAIN or time.time() > start + self.lock_timeout:
                   raise
            time.sleep(0.5)

    def __exit__(self, type_, value, traceback):
        fcntl.flock(self._lockfd, fcntl.LOCK_UN)
        os.close(self._lockfd)
        try:
            os.unlink(self.lock_file)
        except:
            pass

    def run_openssl(self, command, **kwargs):
        cmdline = shlex.split(command % kwargs)
        process = subprocess.Popen(cmdline, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        res = process.communicate()
        if process.returncode:
            raise PopenError("Popen returned nonzero code", process.returncode, ' '.join(cmdline), res[0], res[1])
        return res

    def new_cert(self, client, csr, pwd):
        if client.status != "Issuable" or not client.pwd:
            raise ClientNotIssuableError("Client not allowed to issue request or password not set")
        if client.pwd != pwd:
            raise AuthenticationError("Wrong credentials")
        dn = self.subject_dn_template.replace("/", "//").replace(",", "/") % client.name
        if not dn.startswith("/"):
            dn = "/" + dn
        with tempfile.NamedTemporaryFile(dir=self.csr_dir, delete=False) as csr_file:
            csr_file.write(csr)
        with self:  # lock dance
            with open(self.serial_file) as f:
                serial = f.read().strip()
            output = self.run_openssl(self.openssl_sign, cnf = self.cnf_file, csr = csr_file.name, dn = dn)
        self.log.debug(output)
        os.rename(csr_file.name, pth.join(self.csr_dir, serial + ".csr.pem"))
        client_pem_name = pth.join(self.client_dir, client.name, serial + ".cert.pem")
        os.symlink(pth.join(self.newcerts_dir, serial + ".pem"), client_pem_name)
        with open(client_pem_name) as pem:
            cert = M2Crypto.X509.load_cert_string(pem.read(), M2Crypto.X509.FORMAT_PEM)
        client.update(status="Passive", pwd=None)
        self.save_client(client)
        return cert

    def __str__(self):
        return "%s<%s>" % (type(self).__name__, self.base_dir)


class EjbcaRegistry(OpenSSLRegistry):

    status_ejbca_to_str = {
        ejbcaws.STATUS_NEW: "Issuable",
        ejbcaws.STATUS_GENERATED: "Passive",
        ejbcaws.STATUS_INITIALIZED: "New",
        ejbcaws.STATUS_HISTORICAL: "Disabled"
    }
    status_str_to_ejbca = dict((v, k) for k, v in status_ejbca_to_str.items())

    def __init__(self, log, url, cert=None, key=None,
                 ca_name="", certificate_profile_name="", end_entity_profile_name="",
                 subject_dn_template="%s", username_suffix=""):
        self.log = log
        self.ejbca = ejbcaws.Ejbca(url, cert, key)
        self.ca_name = ca_name
        self.certificate_profile_name = certificate_profile_name
        self.end_entity_profile_name = end_entity_profile_name
        self.subject_dn_template = subject_dn_template
        self.username_suffix = username_suffix

    def client_data(self, ejbca_data):
        ejbca_username = ejbca_data["username"]
        username = ejbca_username[:-len(self.username_suffix)] if ejbca_username.endswith(self.username_suffix) else ejbca_username
        admins = [u if not u.startswith("RFC822NAME") else u[11:] for u in ejbca_data["subjectAltName"].split(",")]
        status = self.status_ejbca_to_str.get(ejbca_data["status"], "Other")
        return username, admins, status, None, ejbca_data

    def get_clients(self):
        return [Client(*self.client_data(u)) for u in self.ejbca.get_users()]

    def get_client(self, name):
        users = self.ejbca.find_user(ejbcaws.MATCH_WITH_USERNAME, ejbcaws.MATCH_TYPE_EQUALS, name + self.username_suffix)
        if len(users) > 1:
            raise LookupError("%d users %s found (more than one?!)" % (len(users), name))
        if not users:
            return None
        return Client(*self.client_data(users[0]))

    def save_client(self, client):
        edata = client.opaque or dict(
            caName=self.ca_name,
            certificateProfileName=self.certificate_profile_name,
            endEntityProfileName=self.end_entity_profile_name,
            keyRecoverable=False,
            sendNotification=False,
            tokenType=ejbcaws.TOKEN_TYPE_USERGENERATED,
            password = "".join((random.choice(string.ascii_letters + string.digits) for dummy in range(16))),
            clearPwd = True,
            username = client.name + self.username_suffix,
            subjectDN = self.subject_dn_template % client.name
        )
        edata["subjectAltName"] = ",".join(("RFC822NAME=%s" % a for a in client.admins))
        edata["status"] = self.status_str_to_ejbca.get(client.status, edata["status"])
        if client.pwd:
            edata["password"] = client.pwd
            edata["clearPwd"] = True
        self.ejbca.edit_user(edata)

    def get_certs(self, client):
        return self.ejbca.find_certs(client.opaque["username"], validOnly=False)

    def new_cert(self, client, csr, pwd):
        cert = self.ejbca.pkcs10_request(
            client.opaque["username"],
            pwd, csr, 0, ejbcaws.RESPONSETYPE_CERTIFICATE)
        return cert

    def __str__(self):
        return self.ejbca.get_version()


def format_cert(cert):
    return (
        "Subject:     %s\n"
        "Validity:    %s - %s\n"
        "Serial:      %s\n"
        "Fingerprint: md5:%s, sha1:%s\n"
        "Issuer:      %s\n"
    ) % (
        cert.get_subject().as_text(),
        cert.get_not_before().get_datetime().isoformat(),
        cert.get_not_after().get_datetime().isoformat(),
        ":".join(["%02x" % ord(c) for c in struct.pack('!Q', cert.get_serial_number())]),
        cert.get_fingerprint("md5"),
        cert.get_fingerprint("sha1"),
        cert.get_issuer().as_text()
    )


# Server side

class OptionalAuthenticator(ObjectBase):

    def __init__(self, req, log):
        ObjectBase.__init__(self, req, log)


    def __str__(self):
        return "%s(req=%s)" % (type(self).__name__, type(self.req).__name__)


    def authenticate(self, env, args):
        cert_name = env.get("SSL_CLIENT_S_DN_CN")

        if cert_name:
            if cert_name != args.setdefault("name", [cert_name])[0]:
                exception = self.req.error(message="authenticate: client name does not correspond with certificate", error=403, cn = cert_name, args = args)
                exception.log(self.log)
                return None

            verify = env.get("SSL_CLIENT_VERIFY")
            if verify != "SUCCESS":
                exception = self.req.error(message="authenticate: certificate present but verification failed", error=403, cn = cert_name, args = args, verify=verify)
                exception.log(self.log)
                return None

            return "cert"   # Ok, client authorized by valid certificate

        else:
            try:
                args["password"][0]
                return "pwd"    # Ok, pass on, but getCert will have to rely on certificate registry password
            except KeyError, IndexError:
                exception = self.req.error(message="authenticate: no certificate nor password present", error=403, cn = cert_name, args = args)
                exception.log(self.log)
                return None


    def authorize(self, env, client, path, method):
        return True


class CertHandler(ObjectBase):

    def __init__(self, req, log, registry):
        ObjectBase.__init__(self, req, log)
        self.registry = registry
        self.local_ip_addresses = [netifaces.ifaddresses(iface)[netifaces.AF_INET][0]['addr'] for iface in netifaces.interfaces() if netifaces.AF_INET in netifaces.ifaddresses(iface)]

    @expose(read=1, debug=1)
    def getCert(self, csr_data=None, name=None, password=None):
        if not (name and csr_data):
            raise self.req.error(message="Wrong or missing arguments", error=400, name=name, password=password)
        client = self.registry.get_client(name[0])
        if not client:
            raise self.req.error(message="Unknown client", error=403, name=name, password=password)
        self.log.info("Client %s" % client)
        if self.req.client == "cert":
            # Correctly authenticated by cert, most probably not preactivated with password,
            # so generate oneshot password and allow now
            password = ["".join((random.choice(string.ascii_letters + string.digits) for dummy in range(16)))]
            self.log.debug("Authorized by X509, enabling cert generation with password %s" % password)
            try:
                client.update(status="Issuable", pwd=password[0])
                self.registry.save_client(client)
            except ClientDisabledError as e:
                raise self.req.error(message="Error enabling cert generation", error=403, exc=sys.exc_info())
        if not password:
            raise self.req.error(message="Missing password and certificate validation failed", error=403, name=name, password=password)
        try:
            newcert = self.registry.new_cert(client, csr_data, password[0])
        except Exception as e:
            raise self.req.error(message="Processing error", error=403, exc=sys.exc_info())
        self.log.info("Generated.")
        return [("Content-Type", "application/x-pem-file")], newcert.as_pem()


    @expose(read=1, debug=1)
    def getToken(self, csr_data=None, name=None, password=None):
        if not (name):
            raise self.req.error(message="Wrong or missing arguments", error=400, name=name)

        if not self._same_subnet():
            raise self.req.error(message="Forbidden", error=403)

        try:
            register_client(self.registry, name[0], admins="bodik@cesnet.cz")
        except:
            pass
        applicant(self.registry, name[0], password=password[0])
        return [("Content-Type", "text/plain")], ""


    @expose(read=1, debug=1)
    def getCacert(self, csr_data=None, password=None):
        if not self._same_subnet():
            raise self.req.error(message="Forbidden", error=403)

        with open("/opt/warden_server/ca/certs/ca.cert.pem", "r") as f:
            data = f.read()
        return [("Content-Type", "text/plain")], data


    @expose(read=1, debug=1)
    def registerSensor(self, csr_data=None, name=None, password=None):
        if not (name):
            raise self.req.error(message="Wrong or missing arguments", error=400, name=name)

        if not self._same_subnet():
            raise self.req.error(message="Forbidden", error=403)

        hostname = self._resolve_client_address(self.req.env["REMOTE_ADDR"])
        try:
            cmd = "/usr/bin/python /opt/warden_server/warden_server.py register --name {client_name} --hostname {hostname} --requestor bodik@cesnet.cz --read --write --notest".format(client_name=name[0], hostname=hostname)
            self.log.debug(cmd)
            data = subprocess.check_output(shlex.split(cmd))
        except subprocess.CalledProcessError as e:
            if ( e.returncode == 101 ):
                # client already register, we accept the state for cloud testing
                self.log.warn("client already registerd")
            else:
                # client registration failed for other reason
                raise e

        except Exception as e:
            # generic exception during registration process
            raise e

        return [("Content-Type", "text/plain")], ""


    def _resolve_client_address(self, ip):
        try:
            socket.setdefaulttimeout(5)
            ret = socket.gethostbyaddr(ip)[0]
        except Exception as e:
            self.log.warn("%s %s" % (ip, e))
            raise e
        return ret

    def _same_subnet(self):
        if self.req.env["REMOTE_ADDR"] in self.local_ip_addresses:
            return True

        data = subprocess.check_output(shlex.split("ip neigh show")).splitlines()
        for tmp in data:
            #192.168.214.49 dev eth0 lladdr a0:f3:e4:32:86:01 REACHABLE
            pattern = "^%s dev [a-z0-9]+ lladdr ([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}) " % self.req.env["REMOTE_ADDR"]
            if re.match(pattern, tmp):
                return True
        return False


# Order in which the base objects must get initialized
section_order = ("log", "auth", "registry", "handler", "server")

# List of sections and objects, configured by them
# First object in each object list is the default one, otherwise
# "type" keyword in section may be used to choose other
section_def = {
    "log": [FileLogger, SysLogger],
    "auth": [OptionalAuthenticator],
    "registry": [OpenSSLRegistry, EjbcaRegistry],
    "handler": [CertHandler],
    "server": [Server]
}

# Object parameter conversions and defaults
param_def = {
    FileLogger: warden_server.param_def[FileLogger],
    SysLogger: warden_server.param_def[SysLogger],
    Server: warden_server.param_def[Server],
    OptionalAuthenticator: {
        "req": {"type": "obj", "default": "req"},
        "log": {"type": "obj", "default": "log"}
    },
    OpenSSLRegistry: {
        "log":  {"type": "obj", "default": "log"},
        "base_dir": {"type": "str", "default": pth.join(pth.dirname(__file__), "ca")},
        "subject_dn_template": {"type": "str", "default": "DC=cz,DC=example-ca,DC=warden,CN=%s"},
        "openssl_sign": {"type": "str", "default": "openssl ca -config %(cnf)s -batch -extensions server_cert -days 375 -notext -md sha256 -in %(csr)s -subj '%(dn)s'"},
        "lock_timeout": {"type": "natural", "default": "3"}
    },
    EjbcaRegistry: {
        "log":  {"type": "obj", "default": "log"},
        "url": {"type": "str", "default": "https://ejbca.example.org/ejbca/ejbcaws/ejbcaws?wsdl"},
        "cert": {"type": "filepath", "default": pth.join(pth.dirname(__file__), "warden_ra.cert.pem")},
        "key": {"type": "filepath", "default": pth.join(pth.dirname(__file__), "warden_ra.key.pem")},
        "ca_name": {"type": "str", "default": "Example CA"},
        "certificate_profile_name": {"type": "str", "default": "Example"},
        "end_entity_profile_name": {"type": "str", "default": "Example EE"},
        "subject_dn_template": {"type": "str", "default": "DC=cz,DC=example-ca,DC=warden,CN=%s"},
        "username_suffix": {"type": "str", "default": "@warden"}
    },
    CertHandler: {
        "req": {"type": "obj", "default": "req"},
        "log": {"type": "obj", "default": "log"},
        "registry": {"type": "obj", "default": "registry"}
    }
}

param_def[FileLogger]["filename"] = {"type": "filepath", "default": pth.join(pth.dirname(__file__), pth.splitext(pth.split(__file__)[1])[0] + ".log")}


def build_server(conf):
    return warden_server.build_server(conf, section_order, section_def, param_def)


# Command line

def list_clients(registry, name=None, verbose=False, show_cert=True):
    if name is not None:
        client = registry.get_client(name)
        if client is None:
            print "No such client."
            return
        else:
            print(client.str(verbose))
            if show_cert:
                for cert in sorted(registry.get_certs(client), key=lambda c: c.get_not_after().get_datetime()):
                    print(format_cert(cert))
                    if verbose:
                        print(cert.as_text())
    else:
        clients = registry.get_clients()
        for client in sorted(clients, key=operator.attrgetter("name")):
            print(client.str(verbose))


def register_client(registry, name, admins=None, verbose=False):
    try:
        client = registry.new_client(name, admins)
    except LookupError as e:
        print(e)
        return
    registry.save_client(client)
    list_clients(registry, name, verbose, show_cert=False)


def applicant(registry, name, password=None, verbose=False):
    client = registry.get_client(name)
    if not client:
        print "No such client."
        return
    if password is None:
        password = "".join((random.choice(string.ascii_letters + string.digits) for dummy in range(16)))
    try:
        client.update(status="Issuable", pwd=password)
    except ClientDisabledError:
        print "This client is disabled. Use 'enable' first."
        return
    registry.save_client(client)
    list_clients(registry, name, verbose, show_cert=False)
    print("Application password is: %s\n" % password)


def enable(registry, name, verbose=False):
    client = registry.get_client(name)
    if not client:
        print "No such client."
        return
    client.update(status="Passive")
    registry.save_client(client)
    list_clients(registry, name, verbose, show_cert=False)


def disable(registry, name, verbose=False):
    client = registry.get_client(name)
    if not client:
        print "No such client."
        return
    client.update(status="Disabled")
    registry.save_client(client)
    list_clients(registry, name, verbose, show_cert=False)


def request(registry, key, csr, verbose=False):
    openssl = subprocess.Popen(
        [
            "openssl", "req", "-new", "-nodes", "-batch",
            "-keyout", key,
            "-out", csr,
            "-config", "/dev/stdin"
        ], stdin=subprocess.PIPE
    )
    openssl.stdin.write(
        "distinguished_name=req_distinguished_name\n"
        "prompt=no\n"
        "\n"
        "[req_distinguished_name]\n"
        "commonName=dummy"
    )
    openssl.stdin.close()
    openssl.wait()
    if verbose:
        with open(csr, "r") as f:
            print(f.read())


def gen_cert(registry, name, csr, cert, password, verbose=False):
    with open(csr, "r") as f:
        csr_data = f.read()
    client = registry.get_client(name)
    newcert = registry.new_cert(client, csr_data, password)
    print(format_cert(newcert))
    if verbose:
        print(newcert.as_text())
        print(newcert.as_pem())
    with open(cert, "w") as f:
        f.write(newcert.as_text())
        f.write(newcert.as_pem())


def get_args():
    argp = argparse.ArgumentParser(
        description="Warden server certificate registry", add_help=False)
    argp.add_argument("--help", action="help",
        help="show this help message and exit")
    argp.add_argument("-c", "--config",
        help="path to configuration file")
    argp.add_argument("-v", "--verbose", action="store_true", default=False,
        help="be more chatty")
    subargp = argp.add_subparsers(title="commands")

    subargp_list = subargp.add_parser("list", add_help=False,
        description="List registered clients.",
        help="list clients")
    subargp_list.set_defaults(command=list_clients)
    subargp_list.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_list.add_argument("--name", action="store", type=str,
        help="client name")

    subargp_reg = subargp.add_parser("register", add_help=False,
        description="Add client registration entry.",
        help="register client")
    subargp_reg.set_defaults(command=register_client)
    subargp_reg.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_reg.add_argument("--name", action="store", type=str,
        required=True, help="client name")
    subargp_reg.add_argument("--admins", action="store", type=str,
        required=True, nargs="*", help="administrator list")

    subargp_apply = subargp.add_parser("applicant", add_help=False,
        description="Set client into certificate application mode and set its password",
        help="allow for certificate application")
    subargp_apply.set_defaults(command=applicant)
    subargp_apply.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_apply.add_argument("--name", action="store", type=str,
        required=True, help="client name")
    subargp_apply.add_argument("--password", action="store", type=str,
        help="password for application (will be autogenerated if not set)")

    subargp_enable = subargp.add_parser("enable", add_help=False,
        description="Enable this client",
        help="enable this client")
    subargp_enable.set_defaults(command=enable)
    subargp_enable.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_enable.add_argument("--name", action="store", type=str,
        required=True, help="client name")

    subargp_disable = subargp.add_parser("disable", add_help=False,
        description="Disable this client",
        help="disable this client (no more applications until enabled again)")
    subargp_disable.set_defaults(command=disable)
    subargp_disable.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_disable.add_argument("--name", action="store", type=str,
        required=True, help="client name")

    subargp_req = subargp.add_parser("request", add_help=False,
        description="Generate certificate request",
        help="generate CSR")
    subargp_req.set_defaults(command=request)
    subargp_req.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_req.add_argument("--key", action="store", type=str,
        required=True, help="file for saving the key")
    subargp_req.add_argument("--csr", action="store", type=str,
        required=True, help="file for saving the request")

    subargp_cert = subargp.add_parser("gencert", add_help=False,
        description="Request new certificate from registry",
        help="get new certificate")
    subargp_cert.set_defaults(command=gen_cert)
    subargp_cert.add_argument("--help", action="help",
        help="show this help message and exit")
    subargp_cert.add_argument("--name", action="store", type=str,
        required=True, help="client name")
    subargp_cert.add_argument("--csr", action="store", type=str,
        required=True, help="file for saving the request")
    subargp_cert.add_argument("--cert", action="store", type=str,
        required=True, help="file for saving the new certificate")
    subargp_cert.add_argument("--password", action="store", type=str,
        required=True, help="password for application")

    return argp.parse_args()


if __name__ == "__main__":
    args = get_args()
    config = pth.join(pth.dirname(__file__), args.config or "warden_ra.cfg")
    server = build_server(read_cfg(config))
    registry = server.handler.registry
    if args.verbose:
        print(registry)
    command = args.command
    subargs = vars(args)
    del subargs["command"]
    del subargs["config"]
    sys.exit(command(registry, **subargs))
