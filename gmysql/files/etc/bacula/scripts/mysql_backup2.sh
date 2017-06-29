#!/bin/bash

BASE="/var/lib/bacula"
NAME="mysql,$(hostname -f)"
BACKUPDIR="${BASE}/${NAME}"
ARCHIVE="${BASE}/${NAME}.tar.gz"

HOST="localhost"
PORT="3306"

DATABASES=0
TABLES=0
ERRORS=0

if [ ! -d ${BACKUPDIR} ]; then
	mkdir -p ${BACKUPDIR}
else
 	find ${BACKUPDIR} -type f -delete
fi

for db in $(mysql -h${HOST} -P${PORT} -NBe 'show databases'); do
        if [ "$db" = "performance_schema" ]; then continue; fi
        if [ "$db" = "information_schema" ]; then continue; fi
	DATABASES=$(($DATABASES+1))

	for table in $(mysql -h${HOST} -P${PORT} -NBe 'show tables' $db); do
		TABLES=$(($TABLES+1))
		OPTS="--triggers --events"
                if [ $db = "mysql" ]; then
                        if [ "$table" = "general_log" -o "$table" = "slow_log" ]; then
                                OPTS="$OPTS --skip-lock-tables"
                        fi
                fi

                mysqldump $OPTS -h$HOST -P$PORT $db $table > ${BACKUPDIR}/${NAME},${db},${table}.sql
		if [ $? -ne 0 ]; then
			echo "ERROR: cannot dump $db $table"
			ERRORS=$(($ERRORS+1))
		fi
	done
done

tar czf $ARCHIVE ${BACKUPDIR} || exit 1
rm -r ${BACKUPDIR}

echo -n "db archive: "
ls -l $ARCHIVE
echo "RES: ERRORS=$ERRORS DATABASES=$DATABASES TABLES=$TABLES"

if [ $DATABASES -eq 0 ]; then
	echo "ERROR: no databases dumped"
	ERRORS=1
fi

exit $ERRORS

