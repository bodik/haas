if [ -f /opt/warden_tologstash/warden_tologstash.py ]; then
        echo "INFO: WARDENTOLOGSTASHCHECK ======================="

        for all in warden3::tologstash; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi

