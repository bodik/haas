# warden3 -- Module for various warden3 ecosystem components

## Scripts

**bin/install_ssl_warden_ra.sh** -- installs x509 certificate from warden ra

**bin/register_sensor.sh -- registers sensor at warden ra

**bin/verify_ssl_warden_ra.sh -- verifies presence of certificate and registration flag 

## defined_types: warden3::racert

Resource will ensure provisioning of SSL certificated used by other w3 components.
If certificate is not present in install_dir, module will generate new key and
request signing it from warden ra/ca service located on warden server

### Parameters

**destdir** -- directory to generate certificate to

**owner** -- destdir owner

**group** -- destdir group

**warden_ra_url** -- name or ip of warden server, overrides autodiscovery

**warden_ra_service** -- service name to be discovered

**mode** -- 


## puppet_classes: warden3::ra

Class will ensure installation of warden3 semi-automated registration and
certification authority for testing.

### Parameters

**install_dir** -- installation directory

**service_port** -- port for apache virtualhost

### Examples

Usage

```
include warden3::ra
```

## puppet_classes: warden3::server

Class will ensure installation of warden3 server: apache2, wsgi, server, mysqldb, configuration

### Parameters

**install_dir** -- directory to install w3 server

**port** -- port to listen with apache vhost

**mysql_*** -- parameters for mysql database for w3 server

**service_port** -- 

**mysql_host** -- 

**mysql_port** -- 

**mysql_db** -- 

**mysql_password** -- 


## puppet_classes: warden3::tester

Class will ensure installation of example warden3 testing client. Tester will
generate ammount of idea messages and sends them to w3 server.

### Parameters

**install_dir** -- directory to install w3 server

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery


## puppet_classes: warden3::tologstash

Class will ensure installation of warden3 client which receives new events from server and sends them to logstash

### Parameters

**install_dir** -- directory to install the component

**tologstash_user** -- user to run the service

**logstash_server_warden_server** -- logstash server host

**logstash_server_warden_port** -- port for warden stream input

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

**logstash_server** -- 


## puppet_functions: warden_config_dbpassword

gets db password from warden config file

### Parameters

**arg0** -- confifile path

### Return

password string


