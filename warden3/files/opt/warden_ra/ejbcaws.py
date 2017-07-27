#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2016, CESNET, z. s. p. o.
# Use of this source is governed by an ISC license, see LICENSE file.

import urllib2
import httplib
import socket
import base64
import suds.transport.http
import suds.client
import M2Crypto


STATUS_FAILED = 11
STATUS_GENERATED = 40
STATUS_HISTORICAL = 60
STATUS_INITIALIZED = 20
STATUS_INPROCESS = 30
STATUS_KEYRECOVERY = 70
STATUS_NEW = 10
STATUS_REVOKED = 50

MATCH_TYPE_BEGINSWITH = 1
MATCH_TYPE_CONTAINS = 2
MATCH_TYPE_EQUALS = 0
MATCH_WITH_CA = 5
MATCH_WITH_CERTIFICATEPROFILE = 4
MATCH_WITH_COMMONNAME = 101
MATCH_WITH_COUNTRY = 112
MATCH_WITH_DIRECTORYNAME = 204
MATCH_WITH_DN = 7
MATCH_WITH_DNSERIALNUMBER = 102
MATCH_WITH_DNSNAME = 201
MATCH_WITH_DOMAINCOMPONENT = 111
MATCH_WITH_EDIPARTNAME = 205
MATCH_WITH_EMAIL = 1
MATCH_WITH_ENDENTITYPROFILE = 3
MATCH_WITH_GIVENNAME = 103
MATCH_WITH_GUID = 209
MATCH_WITH_INITIALS = 104
MATCH_WITH_IPADDRESS = 202
MATCH_WITH_LOCALE = 109
MATCH_WITH_ORGANIZATION = 108
MATCH_WITH_ORGANIZATIONUNIT = 107
MATCH_WITH_REGISTEREDID = 207
MATCH_WITH_RFC822NAME = 200
MATCH_WITH_STATE = 110
MATCH_WITH_STATUS = 2
MATCH_WITH_SURNAME = 105
MATCH_WITH_TITLE = 106
MATCH_WITH_TOKEN = 6
MATCH_WITH_UID = 100
MATCH_WITH_UPN = 208
MATCH_WITH_URI = 206
MATCH_WITH_USERNAME = 0
MATCH_WITH_X400ADDRESS = 203

TOKEN_TYPE_JKS = "JKS"
TOKEN_TYPE_P12 = "P12"
TOKEN_TYPE_PEM = "PEM"
TOKEN_TYPE_USERGENERATED = "USERGENERATED"

VIEW_RIGHTS = "/view_end_entity"
EDIT_RIGHTS = "/edit_end_entity"
CREATE_RIGHTS = "/create_end_entity"
DELETE_RIGHTS = "/delete_end_entity"
REVOKE_RIGHTS = "/revoke_end_entity"
HISTORY_RIGHTS = "/view_end_entity_history"
APPROVAL_RIGHTS = "/approve_end_entity"
HARDTOKEN_RIGHTS = "/view_hardtoken"
HARDTOKEN_PUKDATA_RIGHTS = "/view_hardtoken/puk_data"
KEYRECOVERY_RIGHTS = "/keyrecovery"

ENDENTITYPROFILEBASE = "/endentityprofilesrules"
ENDENTITYPROFILEPREFIX = "/endentityprofilesrules/"
USERDATASOURCEBASE = "/userdatasourcesrules"
USERDATASOURCEPREFIX = "/userdatasourcesrules/"
UDS_FETCH_RIGHTS = "/fetch_userdata"
UDS_REMOVE_RIGHTS = "/remove_userdata"

CABASE = "/ca"
CAPREFIX = "/ca/"
ROLE_PUBLICWEBUSER = "/public_web_user"
ROLE_ADMINISTRATOR = "/administrator"
ROLE_SUPERADMINISTRATOR = "/super_administrator"
REGULAR_CAFUNCTIONALTY = "/ca_functionality"
REGULAR_CABASICFUNCTIONS = "/ca_functionality/basic_functions"
REGULAR_ACTIVATECA = "/ca_functionality/basic_functions/activate_ca"
REGULAR_RENEWCA = "/ca_functionality/renew_ca"
REGULAR_VIEWCERTIFICATE = "/ca_functionality/view_certificate"
REGULAR_APPROVECAACTION = "/ca_functionality/approve_caaction"
REGULAR_CREATECRL = "/ca_functionality/create_crl"
REGULAR_EDITCERTIFICATEPROFILES = "/ca_functionality/edit_certificate_profiles"
REGULAR_CREATECERTIFICATE = "/ca_functionality/create_certificate"
REGULAR_STORECERTIFICATE = "/ca_functionality/store_certificate"
REGULAR_RAFUNCTIONALITY = "/ra_functionality"
REGULAR_EDITENDENTITYPROFILES = "/ra_functionality/edit_end_entity_profiles"
REGULAR_EDITUSERDATASOURCES = "/ra_functionality/edit_user_data_sources"
REGULAR_VIEWENDENTITY = "/ra_functionality/view_end_entity"
REGULAR_CREATEENDENTITY = "/ra_functionality/create_end_entity"
REGULAR_EDITENDENTITY = "/ra_functionality/edit_end_entity"
REGULAR_DELETEENDENTITY = "/ra_functionality/delete_end_entity"
REGULAR_REVOKEENDENTITY = "/ra_functionality/revoke_end_entity"
REGULAR_VIEWENDENTITYHISTORY = "/ra_functionality/view_end_entity_history"
REGULAR_APPROVEENDENTITY = "/ra_functionality/approve_end_entity"
REGULAR_LOGFUNCTIONALITY = "/log_functionality"
REGULAR_VIEWLOG = "/log_functionality/view_log"
REGULAR_LOGCONFIGURATION = "/log_functionality/edit_log_configuration"
REGULAR_LOG_CUSTOM_EVENTS = "/log_functionality/log_custom_events"
REGULAR_SYSTEMFUNCTIONALITY = "/system_functionality"
REGULAR_EDITADMINISTRATORPRIVILEDGES = "/system_functionality/edit_administrator_privileges"
REGULAR_EDITSYSTEMCONFIGURATION = "/system_functionality/edit_systemconfiguration"
REGULAR_VIEWHARDTOKENS = "/ra_functionality/view_hardtoken"
REGULAR_VIEWPUKS = "/ra_functionality/view_hardtoken/puk_data"
REGULAR_KEYRECOVERY = "/ra_functionality/keyrecovery"

HARDTOKEN_HARDTOKENFUNCTIONALITY = "/hardtoken_functionality"
HARDTOKEN_EDITHARDTOKENISSUERS = "/hardtoken_functionality/edit_hardtoken_issuers"
HARDTOKEN_EDITHARDTOKENPROFILES = "/hardtoken_functionality/edit_hardtoken_profiles"
HARDTOKEN_ISSUEHARDTOKENS = "/hardtoken_functionality/issue_hardtokens"
HARDTOKEN_ISSUEHARDTOKENADMINISTRATORS = "/hardtoken_functionality/issue_hardtoken_administrators"

RESPONSETYPE_CERTIFICATE = "CERTIFICATE"
RESPONSETYPE_PKCS7 = "PKCS7"
RESPONSETYPE_PKCS7WITHCHAIN = "PKCS7WITHCHAIN"

NOT_REVOKED = -1
REVOKATION_REASON_UNSPECIFIED = 0
REVOKATION_REASON_KEYCOMPROMISE = 1
REVOKATION_REASON_CACOMPROMISE = 2
REVOKATION_REASON_AFFILIATIONCHANGED = 3
REVOKATION_REASON_SUPERSEDED = 4
REVOKATION_REASON_CESSATIONOFOPERATION = 5
REVOKATION_REASON_CERTIFICATEHOLD = 6
REVOKATION_REASON_REMOVEFROMCRL = 8
REVOKATION_REASON_PRIVILEGESWITHDRAWN = 9
REVOKATION_REASON_AACOMPROMISE = 10


class HTTPSClientAuthHandler(urllib2.HTTPSHandler):

    def __init__(self, key, cert):
        urllib2.HTTPSHandler.__init__(self)
        self.key = key
        self.cert = cert

    def https_open(self, req):
        return self.do_open(self.get_connection, req)

    def get_connection(self, host, timeout=5):
        return httplib.HTTPSConnection(host, key_file=self.key, cert_file=self.cert, timeout=timeout)


class HTTPSClientCertTransport(suds.transport.http.HttpTransport):

    def __init__(self, key, cert, *args, **kwargs):
        suds.transport.http.HttpTransport.__init__(self, *args, **kwargs)
        self.key = key
        self.cert = cert

    def u2open(self, u2request):
        tm = self.options.timeout
        url = urllib2.build_opener(HTTPSClientAuthHandler(self.key, self.cert))
        if self.u2ver() < 2.6:
            socket.setdefaulttimeout(tm)
            return url.open(u2request)
        else:
            return url.open(u2request, timeout=tm)


class Ejbca(object):

    def __init__(self, url, cert=None, key=None):
        self.url = url
        self.cert = cert
        self.key = key
        self.transport = HTTPSClientCertTransport(self.key, self.cert) if self.cert else None
        self.wsclient = suds.client.Client(self.url, transport=self.transport)


    def get_version(self):
        return self.wsclient.service.getEjbcaVersion()


    def get_users(self):
        return self.find_user(MATCH_WITH_DN, MATCH_TYPE_CONTAINS, "=")


    def find_user(self, matchwith, matchtype, matchvalue):
        usermatch = self.wsclient.factory.create('userMatch')
        usermatch.matchwith = matchwith
        usermatch.matchtype = matchtype
        usermatch.matchvalue = matchvalue
        return self.wsclient.service.findUser(usermatch)


    def edit_user(self, user):
        return self.wsclient.service.editUser(user)


    def _decode_ejbca_cert(self, double_mess):
        single_mess = base64.b64decode(double_mess)
        cert_data = base64.b64decode(single_mess)
        cert = M2Crypto.X509.load_cert_string(cert_data, M2Crypto.X509.FORMAT_DER)
        return cert


    def pkcs10_request(self, username, password, pkcs10, hardTokenSN, responseType):
        res = self.wsclient.service.pkcs10Request(
            arg0=username,
            arg1=password,
            arg2=pkcs10,
            arg3=hardTokenSN,
            arg4=responseType)
        return self._decode_ejbca_cert(res["data"])


    def find_certs(self, loginName, validOnly=False):
        reslist = self.wsclient.service.findCerts(
            arg0=loginName,
            arg1=validOnly)
        certs = []
        for res in reslist:
            double_mess = res["certificateData"]
            if double_mess is not None:
                cert = self._decode_ejbca_cert(double_mess)
                cert.ejbca_status = res["type"]
                certs.append(cert)
        return certs
