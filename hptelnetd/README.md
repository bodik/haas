# hptelnetd -- HaaS module for telnetd

## Scripts

**bin/vm_cleanup.sh** -- haas helper

**bin/vm_finalize.sh** -- haas helper

## puppet_classes: hptelnetd

Installs telnetd honeypot and reporting warden client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**telnetd_port** -- Service listen port

**real_telnetd_port** -- Service listen port before redirect

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hptelnetd": }
```

