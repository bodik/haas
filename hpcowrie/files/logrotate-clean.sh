#!/bin/sh

if [ -z "$1" ]; then
	HORIZONT=14
else
	HORIZONT=$1
fi
DATABASE=$(grep '^database =' /opt/cowrie/etc/cowrie.cfg | awk -F'=' '{print $2}')
INSTALL_DIR="/opt/cowrie"



mysql ${DATABASE} -e "
	DELETE FROM auth WHERE session IN (SELECT id FROM sessions WHERE starttime < (NOW() - INTERVAL ${HORIZONT} DAY));
	DELETE FROM downloads WHERE session IN (SELECT id FROM sessions WHERE starttime < (NOW() - INTERVAL ${HORIZONT} DAY));
	DELETE FROM input WHERE session IN (SELECT id FROM sessions WHERE starttime < (NOW() - INTERVAL ${HORIZONT} DAY));
	DELETE FROM ttylog WHERE session IN (SELECT id FROM sessions WHERE starttime < (NOW() - INTERVAL ${HORIZONT} DAY));
	DELETE FROM sessions WHERE starttime < (NOW() - INTERVAL ${HORIZONT} DAY);"

find ${INSTALL_DIR}/var/log/cowrie -type f -ctime +${HORIZONT} -delete 1>/dev/null 2>/dev/null
