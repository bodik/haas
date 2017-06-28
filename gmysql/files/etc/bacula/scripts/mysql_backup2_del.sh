#!/bin/bash

BASE="/var/lib/bacula"
NAME="mysql,$(hostname -f)"
ARCHIVE="${BASE}/${NAME}.tar.gz"
rm -v ${ARCHIVE}

