#!/bin/bash

INSTALL_DIR=$1

cd $INSTALL_DIR
/usr/bin/autoreconf -vi

./configure \
	--prefix=${INSTALL_DIR} \
	--with-python=/usr/bin/python3 \
	--with-cython-dir=/usr/bin \
	--with-ev-include=/usr/include \
	--with-ev-lib=/usr/lib \
	--with-emu-lib=/usr/lib/libemu \
	--with-emu-include=/usr/include \
	--with-gc-include=/usr/include/gc \
	--enable-nl \
	--with-nl-include=/usr/include/libnl3 \
	--with-nl-lib=/usr/lib 

make
make install
find ${INSTALL_DIR}/etc/dionaea/services-enabled -type f -delete
