# gmysql -- MariaDB server module

Ensures installation of basic MariaDB server using puppetlabs-mysql module and
minimal config and support scripts.

## Scripts

**bin/check_mysql.stretch** -- nagios check

**bin/check_mysql.sh** -- nagios helper

**bin/listgrants.sh** -- list grants for all users

**bin/nopass.sh** -- checks for passwordless accounts, generates random pass on such account


## puppet_classes: gmysql::server

Class installs Mariadb server with basic configuration and basic set of
management scripts for detecting passwordless accounts and backup scripts
(typically suited for bacula or other backup sw). Most of the work is done by
3rdparty module puppetlabs-mysql

### Examples

Usage

```
include gmysql::server
```

