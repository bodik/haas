#!/bin/sh

OUTDIR="OUTPUT"
if [ -d $OUTDIR ]; then
	echo "ERROR: outdir already exists"
	exit 1
fi

mkdir -p ${OUTDIR}
cd $OUTDIR || exit 1

wget --no-parent --mirror --level=2 --recursive $@ #--http-user tomcat --http-passwd tomcat http://localhost:8080/manager/

for all in `find . -type f`; do
	T=$(echo $all | sed 's/\.\///' | sed 's/\//AAAA/g' | sed 's/\?/BBBB/g')
	cp $all data/$T
done

for all in `find data -name '*.1'`; do 
	T=$(echo $all | sed 's/\.1$//')
	mv $all $T
done
