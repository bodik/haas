#!/bin/bash
#

SAVE="/var/lib/bacula"
NAME="mysql,$(hostname -f)"
rm -v ${SAVE}/${NAME}.tar.gz

