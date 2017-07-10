# hpjdwpd

Module installs a reporting warden client service and custom honeypot service

## puppet_classes: hpjdwpd

Installs jdwp honeypot

### Parameters

**install_dir** _String_ -- Installation directory

**service_user** _String_ -- User to run service as

**jdwpd_port** _Integer_ -- Service listen port

**warden_server** _String_ -- warden server hostname

**warden_server_auto** _Boolean_ -- warden server autodiscovery enable flag

**warden_server_service** _String_ -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpjdwpd":
  jdwpd_port => 8001,
  warden_server => "warden-test.cesnet.cz",
}
```

