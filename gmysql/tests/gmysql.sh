#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array=/usr/sbin/mysqld -c 1:1
if [ $? -ne 0 ]; then
        rreturn 1 "$0 mysqld_safe check_procs"
fi

LIST=$(netstat -nlpa | grep "/mysqld" | grep " LISTEN " | awk '{print $4}')
if [ "$LIST" != "127.0.0.1:3306" ]; then
        rreturn 1 "$0 mysqld listen check failed"
fi

mysql -NBe 'show variables' 1>/dev/null
if [ $? -ne 0 ]; then
        rreturn 1 "$0 cannot connect to mysqld"
fi

mysql -NBe 'show grants for "root"@"localhost"' | grep 'PROXY'
if [ $? -ne 1 ]; then
        rreturn 1 "$0 mysqld root proxy privilege"
fi

/puppet/gmysql/bin/nopass.sh -noop
if [ $? -ne 0 ]; then
        rreturn 1 "$0 passwordless accounts found"
fi

