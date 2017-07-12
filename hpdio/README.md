## puppet_classes: hpdio

Installs Dionaea honeypot

### Parameters

**install_dir** -- Installation directory

**dio_user** -- User to run service as

**log_history** -- The number of days the data is stored on

**warden_server** -- warden server hostname

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpdio": }
```

