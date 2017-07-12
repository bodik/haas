#!/bin/sh

if [ -d /var/lib/mysql ]; then
        echo "INFO: CHECK MYSQL ======================"
	pa.sh -v --noop --show_diff -e "include gmysql::server"

        echo "INFO: sh /puppet/gmysql/bin/nopass.sh -noop"
        sh /puppet/gmysql/bin/nopass.sh -noop
fi

