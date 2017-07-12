## puppet_classes: hpcowrie

Installs Cowrie honeypot

### Parameters

**install_dir** -- Installation directory

**cowrie_port** -- Service listen port

**cowrie_user** -- User to run service as

**cowrie_ssh_version_string** -- SSH version announcement

**log_history** -- The number of days the data is stored on

**mysql_host** -- MySQL server with Cowrie database to connect

**mysql_port** -- Port of MySQL server to connect

**mysql_db** -- Database to store Cowrie data

**mysql_password** -- Password to MySQL server authtentication

**warden_server** -- warden server hostname

**warden_server_service** -- avahi name of warden server service for autodiscovery

### Examples

Declaring the class

```
class { "hpcowrie": }
```

