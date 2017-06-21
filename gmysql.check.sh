if [ -d /var/lib/mysql ]; then
        echo "INFO: MYSQLCHECK ======================="

        for all in gmysql::server; do
                echo "INFO: pa.sh --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done

        echo "INFO: sh /puppet/gmysql/bin/nopass.sh -noop"
        sh /puppet/gmysql/bin/nopass.sh -noop
fi



