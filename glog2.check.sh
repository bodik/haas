dpkg -l | grep elasticsearch | grep 5.4 >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: GLOG2CHECK ======================="

        for all in glog::glog2; do
                echo "INFO: pa.sh --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done
fi

