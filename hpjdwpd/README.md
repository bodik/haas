# hpjdwpd

Module installs a reporting warden client service and custom honeypot service

## puppet_classes: hpjdwpd

Installs jdwp honeypot

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**jdwpd_port** -- Service listen port

**warden_server** -- warden server hostname

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpjdwpd":
  jdwpd_port => 8001,
  warden_server => "warden-test.cesnet.cz",
}
```

