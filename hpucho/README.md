## puppet_classes: hpucho::tcp

Installs ucho tcp service

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**port_start** -- lowest port to listen

**port_end** -- highest port to listen

**port_skip** -- list of ports to skip

**warden_server** -- warden server hostname

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::tcp": }
```

## puppet_classes: hpucho::udp

Installs ucho udp service

### Parameters

**install_dir** -- Installation directory

**service_user** -- User to run service as

**port_start** -- lowest port to listen

**port_end** -- highest port to listen

**port_skip** -- list of ports to skip

**warden_server** -- warden server hostname

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::udp": }
```

