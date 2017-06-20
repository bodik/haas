#!/bin/sh

. /puppet/metalib/bin/lib.sh

NOOP=0
usage() { echo "Usage: $0 [-noop]"; exit 1; }
while getopts "n:" o; do
	case "${o}" in
        	n) NOOP=1 ;;
		*) usage ;;
	esac
done
shift $(($OPTIND-1))

RET=0

DATA=$(mysql -Bse "SELECT CONCAT(user, '\@', host) FROM mysql.user WHERE password = '' OR password IS NULL;")
for all in $DATA; do
	RET=1

	if [ $NOOP -eq 1 ]; then
		echo "WARN: Would generate password for $all"
	else
		echo "WARN: Generating password for $all"
		NEWPASS=$(dd if=/dev/urandom bs=100 count=1 2>/dev/null | sha256sum | awk '{print $1}')
		all=`echo $all | sed "s/%/'%'/"`
		mysql -Bse "SET PASSWORD FOR $all = PASSWORD(\"$NEWPASS\");"
		mysql -Bse "FLUSH PRIVILEGES;"
	fi
done


if [ $RET -ne 0 ]; then
	rreturn $RET "$0 passwordless accounts found"
else
	return 0
fi


