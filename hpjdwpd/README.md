# hpjdwpd -- HaaS module for jdwpd

## Scripts

**bin/vm_cleanup.sh** -- haas helper

**bin/vm_finalize.sh** -- haas helper

## puppet_classes: hpjdwpd

Installs jdwp honeypot and reporting warden client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**jdwpd_port** -- Service listen port

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpjdwpd":
  jdwpd_port => 8001,
  warden_server => "warden-test.cesnet.cz",
}
```

