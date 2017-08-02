# hpucho -- HaaS module for ucho

## Scripts

**bin/vm_cleanup.sh** -- haas helper

**bin/vm_finalize.sh** -- haas helper

## puppet_classes: hpucho::tcp

Installs ucho tcp service and warden reporting client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**port_start** -- lowest port to listen

**port_end** -- highest port to listen

**port_skip** -- list of ports to skip

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::tcp": }
```

## puppet_classes: hpucho::udp

Installs ucho udp service and warden reporting client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**port_start** -- lowest port to listen

**port_end** -- highest port to listen

**port_skip** -- list of ports to skip

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::udp": }
```

## puppet_classes: hpucho::web

Installs ucho web service and warden reporting client

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**port** -- port to listen

**personality** -- webserver identification

**content** -- content file

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::web": }
```

