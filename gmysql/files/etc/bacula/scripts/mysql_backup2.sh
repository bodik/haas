#!/bin/bash

export TMPDIR="/tmp/"
export TEMP="/tmp/"
export LANG="C"

SAVE="/var/lib/bacula"
HOST="localhost"
PORT="3306"
NAME="mysql,$(hostname -f)"
BASE=${SAVE}/${NAME}
ARCH=${SAVE}/${NAME}.tar.gz

DBS=0
TABS=0
ERR=0

if [ ! -d ${BASE} ]; then
	mkdir -p ${BASE}
else
 	find ${BASE} -type f -delete
fi

for db in $(mysql -h $HOST -P $PORT -e 'show databases'| sed '1d'); do
	DBS=$(($DBS+1))
	for table in $(mysql -h $HOST -P $PORT -e 'show tables' $db | sed '1d'); do
		TABS=$(($TABS+1))
		OPTS="--triggers --events"

                if [ "x$db" = "xmysql" ]; then
                        if [ "x$table" = "xgeneral_log" -o "x$table" = "xslow_log" ]; then
                                OPTS="$opts --skip-lock-tables"
                        fi
                fi
                if [ "x$db" = "xperformance_schema" ]; then
			#nejaka virtualni databaze, nezalohovat
                        continue;
                fi

                mysqldump $OPTS -h $HOST -P $PORT $db $table > ${BASE}/${NAME},${db},${table}.sql
		if [ $? -ne 0 ]; then
			echo "ERROR: cannt dump $db $table"
			ERR=$(( $ERR + 1))
		fi
	done
done

tar czf $ARCH ${BASE} || exit 1
rm -r ${BASE}

echo -n "db archive: "
ls -l $ARCH
echo "RES: ERR=$ERR DATABASES=$DBS TABLES=$TABS"

if [ $DBS -eq 0 ]; then
	echo "ERROR: no databases dumped"
	ERR=1
fi

exit $ERR

