## puppet_classes: hpucho::tcp

HaaS hpucho tcp
Installs ucho tcp service

### Parameters

**install_dir** _String_ -- Installation directory
**service_user** _String_ -- User to run service as
**port_start** _Integer_ -- lowest port to listen
**port_end** _Integer_ -- highest port to listen
**port_skip** _Array_ -- list of ports to skip
**warden_server** _String_ -- warden server hostname
**warden_server_auto** _Boolean_ -- warden server autodiscovery enable flag
**warden_server_service** _String_ -- avahi name of warden server service for autodiscovery

### Examples

Install service with default warden-server autodiscovery

```
class { "hpucho::tcp": }
```

## puppet_classes: hpucho::udp

### Parameters

**install_dir** _Any_ -- 

**service_user** _Any_ -- 

**port_start** _Any_ -- 

**port_end** _Any_ -- 

**port_skip** _Any_ -- 

**warden_server** _Any_ -- 

**warden_server_auto** _Any_ -- 

**warden_server_service** _Any_ -- 


