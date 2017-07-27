# hpcowrie -- HaaS module for cowrie ssh honeypot

## Scripts

**bin/vm_cleanup.sh** -- haas helper

**bin/vm_finalize.sh** -- haas helper

## puppet_classes: hpcowrie

Installs Cowrie honeypot and warden reporting client

### Parameters

**install_dir** -- Installation directory

**cowrie_port** -- Service listen port

**service_user** -- User to run service as

**cowrie_ssh_version_string** -- SSH version announcement

**log_history** -- The number of days the data is stored on

**mysql_host** -- MySQL server with Cowrie database to connect

**mysql_port** -- Port of MySQL server to connect

**mysql_db** -- Database to store Cowrie data

**mysql_password** -- Password to MySQL server authtentication

**warden_client_name** -- reporting script warden client name

**warden_server_url** -- warden server url to connect

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpcowrie": }
```

