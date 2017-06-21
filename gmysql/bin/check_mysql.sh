#!/bin/sh
/puppet/gmysql/bin/check_mysql.$(facter lsbdistcodename) $@
