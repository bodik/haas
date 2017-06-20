#!/bin/sh

mysql -NBe "SELECT user,host FROM mysql.user;" | while read u d; do
	echo -n "==== "
	mysql -NBe "show grants for '$u'@'$d'"
done

