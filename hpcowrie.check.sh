if [ -f /opt/cowrie/INSTALL.md ]; then
        echo "INFO: HPCOWRIECHECK ======================="

        for all in hpcowrie; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi

