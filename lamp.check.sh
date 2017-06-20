dpkg -l | grep apache2 1>/dev/null 2>/dev/null && test ! -d /home/apache/ 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: LAMPCHECK ======================="

        for all in lamp::apache2; do
                echo "INFO: pa.sh --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done
fi

