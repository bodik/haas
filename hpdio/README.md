# hpcowrie -- HaaS module for dioanea honeypot

## Scripts

**bin/build.sh** -- manifest helper

**bin/vm_cleanup.sh** -- haas helper

**bin/vm_finalize.sh** -- haas helper

## puppet_classes: hpdio

Installs Dionaea honeypot and reporting warden client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**log_history** -- The number of days the data is stored on

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpdio": }
```

